---
layout: post
title:  "GPDB 优化器和 Direct Dispatch"
author: 姚延栋
date:   2016-04-12 09:20:43
categories: gpdb planner direct dispatch
published: true
---

GPDB 主要优化目的是通过各种级别的并行化提高OLAP类查询的速度。 有些特殊查询，只需要访问某个节点的数据，为次 GPDB 提供了 direct dispatch
以优化这类查询。

### PlannedStmt 和 Plan

优化器的输出是 PlannedStmt 结构，它包括了描述查询如何执行的 Plan 树，以及 executor 需要的其他一些和执行状态无关的信息。

* struct Plan *planTree
* 执行器需要的其他和状态无关的信息，例如 query_mem, memory account, slice table 等。

        typedef struct PlannedStmt
        {
            NodeTag type;
            CmdType commandType;    // SELECT/INSERT/UPDATE/DELETE
            ...

            struct Plan *planTree;
            ...
        }

`typedef struct Plan` 表示 plan tree 的一个节点, 是一个抽象类型。 所有具体类型的 plan 节点的第一个字段都是这个
`typedef struct Plan` 结构。 这个结构中包含了和 direct dispatch 相关的信息

    typedef struct Plan {
        NodeTag type;

        int plan_node_id;
        int plan_parent_node_id;

        Cost startup_cost;
        Cost total_cost;

        double plan_rows;
        int plan_width;

        List *targetlist;
        List *qual;

        struct Plan *lefttree;
        struct Plan *righttree;
        List *initPlan;

        ...

        Flow *flow;

        DispatchMethod dispatch;

        DirectDispatchInfo directDispatch;

        int nMotionNodes;
        int nInitPlans;

        Node *sliceTable;

        uint64 operatorMemKB;
        ...
    }

### subquery_planner & cdbparallelize

`PlannedStmt planner(Query *parse, int cursorOptions, ParamListInfo boundParams)` 是优化器的主入口，它对语法解析后的 AST 进行
优化，返回 PlannedStmt。 如果当前query适合direct dispatch，则设置 PlannedStmt->planTree->directDispatch.

    exec_simple_query
        -> pg_plan_queries
            -> pg_plan_query
                -> planner
                    -> standard_planner
                        -> subquery_planner     // primary planning entry point, do all the dirty work. same as PG
                        -> cdbparallelize       // GPDB specific logic

### cdbparallelize

`cdbparallelize` 是 GPDB 并行化 `subquery_planner` 生成的原始 PostgreSQL 查询计划的入口。

* scanForManagedTables: 扫描表
* prescan: 递归扫描plan节点，attach Flow 节点到 plan 节点。 Flow 节点描述了如何并行化 plan。
* apply_motion:

#### prescan

prescan 扫描查询计划节点, 而函数 prescan_walker 是 prescan 的主力.

    prescan
        -> prescan_walker
            -> plan_tree_walker     // walk plan-specific nodes, delegate other nodes to expression_tree_walker()
                -> walk_plan_node_fields    // sort, agg, window, unique, limit, motion, ...
                -> walk_scan_node_fields    // SeqScan, ExternalScan, AOCSScan, IndexScan, BitmapIndexScan
                    -> walk_plan_node_fields
                -> walk_join_node_fields    // Join, NestLoop, MergeJoin, HashJoin
                -> expression_tree_walker   // var, const, rangetblRef, boolexpr, sublink, caseexpr, joinexpr, ...


##### walk_plan_node_fields

walk_plan_node_fields 遍历 Plan 节点的 fields。walker 函数指针指向 prescan_walker。

walker 返回 true 表示停止继续遍历，返回false，表示继续walker。

    bool
    walk_plan_node_fields(Plan *plan,
    					  bool (*walker) (),
    					  void *context)
    {
    	/* target list to be computed at this node */
    	if (walker((Node *) (plan->targetlist), context))
    		return true;

    	/* implicitly ANDed qual conditions */
    	if (walker((Node *) (plan->qual), context))
    		return true;

    	/* input plan tree(s) */
    	if (walker((Node *) (plan->lefttree), context))
    		return true;

    	/* target list to be computed at this node */
    	if (walker((Node *) (plan->righttree), context))
    		return true;

    	/* Init Plan nodes (uncorrelated expr subselects */
    	if (walker((Node *) (plan->initPlan), context))
    		return true;

    	/* Greenplum Database Flow node */
    	if (walker((Node *) (plan->flow), context))
    		return true;

    	return false;
    }

#### apply_motion

apply_motion 和 apply_motion_mutator 将 motion node 加入到plan树中 Flow node 表示的顶层plan tree 中。

这个函数负责判断是否使用 direct dispatch。

    bool needToAssignDirectDispatchContentIds = false;

    switch (query->commandType)
    {
    case CMD_SELECT:
        ...
        needToAssignDirectDispatchContentIds = root->config->gp_enable_direct_dispatch && ! query->intoClause;
        break;

    case CMD_INSERT:
        ...

    case CMD_UPDATE:
    case CMD_DELETE:
        ...
        needToAssignDirectDispatchContentIds = root->config->gp_enable_direct_dispatch;
    }

    if ( needToAssignDirectDispatchContentIds )
    {
    	/* figure out if we can run on a reduced set of nodes */
    	AssignContentIdsToPlanData(query, result, root);
    }

### AssignContentIdsToPlanData(Query *query, Plan *plan, PlannerInfo *root)

    AssignContentIdsToPlanData_Walker((Node*)plan, &data);

相关数据结构：

    // 为 qual 或者 slice 构建 dispatch 信息时需要
    typedef struct DirectDispatchCalculationInfo
    {
        DirectDispatchInfo dd;
        bool haveProcessedAnyCalculations;
    }

    // plan walking 

    FinalizeDirectDispatchDataForSlice(Node *node, ContentIdAssignmentData *data, bool isFromTopRoot)
    {
        // 根据 ContentIdAssignmentData, 得到 DirectDispatchCalculationInfo,

    }