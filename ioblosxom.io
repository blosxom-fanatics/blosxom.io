#!/usr/bin/env io
# vim:ft=io:

doFile("eio.io")

Object p := method(
	writeln(self)
	self
)

IoBlosxom := Object clone do (

	dataDirectory := "data"
	title         := "IoBlosxom"

	Entry := Object clone do (
		file  := File clone
		name  := ""
		title := ""
		body  := ""
		date  := ""

		setFile := method(v,
			self file = v
			self
		)
	)

	run := method(
		self pathInfo   := System getenv("PATH_INFO") ifNilEval("/") split("/")
		self flavour    := pathInfo last afterSeq(".") ifNilEval("html")
		self pathInfo last clipAfterStartOfSeq(".")
		if (self pathInfo last == "index", self pathInfo removeLast)
		self home       := System getenv("SCRIPT_NAME") ifNilEval("/")
		self path       := System getenv("SCRIPT_NAME") ifNilEval("/") split("/") removeLast
		self serverRoot := "http://" .. System getenv("SERVER_NAME")
		self creator    := ""

		self title := "IoBlosxom"
		self entries := self filters(self getEntries(Directory with(dataDirectory)))
		self debugObj := list(pathInfo, flavour)

		self show("template.#{flavour}" interpolate, self)
	)

	filters := method(entries,
		# self pathInfo = list("", "2007", "10")
		y := self pathInfo at(1) ifNilEval("") asNumber
		m := self pathInfo at(2) ifNilEval("") asNumber
		d := self pathInfo at(3) ifNilEval("") asNumber
		entries sortInPlace(date) reverse select (e,
			d isNan ifFalse( if (e date day   != d, continue) )
			m isNan ifFalse( if (e date month != m, continue) )
			if (y isNan,
				if (self pathInfo at(1) isNil,
					true
				,
					e name beginsWithSeq(self pathInfo join("/"))
				)
			,
				if (e date year == y, true)
			)
		)
	)

	show := method(templateName, context,
		template := File openForReading(templateName) contents
		EIo clone setString(template) doInObject(context) print
	)

	// listup entries recursive
	getEntries := method(dir,
		ret := List clone
		ret appendSeq(dir files map(f,
			e := Entry clone setFile(f)
			l := f readLines
			e title = l at(0)
			e body  = l slice(1)
			e date  = f lastDataChangeDate
			e name  = f path asMutable removePrefix(dataDirectory) clipAfterStartOfSeq(".")
			e
		))
		dir folders foreach(d,
			ret appendSeq(getEntries(d))
		)
		ret
	)
)

e := try (
	IoBlosxom clone run
); e catch (
	"""Content-Type: text/plain

	#{e coroutine backTraceString}
	""" asMutable replaceSeq("\t", "") interpolate print
)

