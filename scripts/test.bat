rem Run the test script
rem Manually examine the output file to see the results
call .\lua.bat .\bin\process.lua .\test\main.lua .\test\main.out.lua {N=2}
call .\lua.bat .\test\main.out.lua
call .\lua.bat .\bin\process.lua .\test\tuple.lua .\test\tuple.out.lua
call .\lua.bat .\test\tuple.out.lua
call .\lua.bat .\bin\process.lua .\test\tuple_alt.lua .\test\tuple_alt.out.lua
call .\lua.bat .\test\tuple_alt.out.lua