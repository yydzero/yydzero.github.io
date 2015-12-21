---
layout: post
title:  "Beego session management"
author: 姚延栋
date:   2015-12-21 14:20:43
categories: GPDB
published: false
---


### controller

Controller just use sessions: start, set, get and won't need to care about session management.

	StartSession() {
		...
		if c.CruSession == nil {
			c.CruSession = c.ctx.Input.CruSession
		}
		...
	}


### router

router will handle session matching according to HTTP request info.

	if SessionOn {
		var err error
		context.Input.CruSession, err = GlobalSessions.SessionStart(w, r)
		...
	}

### session manager

session manager has SessionStart() method which will:

	Start session. generate or read the session id from http request.
	if session id exists, return SessionStore with this id.
