print("hai")
srv.Use(mw.Logger())
srv.Use(mw.ExtRoute({
	[".lua"]=mw.Lua(),
	["***"]=static.serve("")
}))
srv.GET("/woot", mw.new(function()
	content(doctype()(
		tag"body"(
			tag"h1"("woot")
		)
	))
end))
srv.GET("/wat", mw.Echo(200, "u wut m8?!?!"))
print("bai")
