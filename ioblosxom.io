#!/usr/bin/env io
# vim:ft=io:

#f := CGI clone parse
#f print

doFile("eio.io")

IoBlosxom := Object clone do (
	Entry := Object clone do (
		file  := File clone
		title := ""
		body  := ""
		time  := ""

		setFile := method(v,
			self file = v
			self
		)
	)

	run := method(
		self pathInfo := System getenv("PATH_INFO") ifNilEval("/") split("/")
		self flavour  := pathInfo last afterSeq(".") ifNilEval("html")
		self pathInfo last clipAfterStartOfSeq(".")

		self title := "IoBlosxom"
		self entries := self filters(self getEntries(Directory with("data")))
		self debugObj := list(pathInfo, flavour)

		self show("template.#{flavour}" interpolate, self)
	)

	filters := method(entries,
		entries sortInPlace(time) reverse
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
			e time  = f lastDataChangeDate
			e
		))
		dir folders foreach(d,
			ret appendSeq(getEntries(d))
		)
		ret
	)
)

Object p := method(
	writeln(self)
	self
)

e := try (
	IoBlosxom clone run
); e catch (
	"""Content-Type: text/plain

	#{e coroutine backTraceString}
	""" asMutable replaceSeq("\t", "") interpolate print
)

