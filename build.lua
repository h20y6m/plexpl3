module = "plexpl3"
bundle = ""

maindir = "."

checkengines = {"ptex","uptex"}
stdengine    = "ptex"
checkformat  = "latex"
checkopts    = " -interaction=nonstopmode -no-guess-input-enc -kanji=utf8 "

installfiles = {"plexpl3.ltx","plexpl3.sty"}

typesetexe  = "platex"
typesetopts = " -interaction=nonstopmode -no-guess-input-enc -kanji=utf8 "

unpackexe  = "ptex"
unpackopts = " -interaction=batchmode -no-guess-input-enc -kanji=utf8 "

-- Do not break non-ascii chars in log file
asciiengines = {}

-- Typeseting with dvipdfmx
function typeset(file,dir,exe)
  dir = dir or "."
  local errorlevel = tex(file,dir,exe)
  if errorlevel ~= 0 then
    return errorlevel
  end
  local name = jobname(file)
  errorlevel = biber(name,dir) + bibtex(name,dir)
  if errorlevel ~= 0 then
    return errorlevel
  end
  for i = 2,typesetruns do
    errorlevel =
      makeindex(name,dir,".glo",".gls",".glg",glossarystyle) +
      makeindex(name,dir,".idx",".ind",".ilg",indexstyle)    +
      tex(file,dir,exe)
    if errorlevel ~= 0 then break end
  end
  -- Run dvipdfmx if .dvi file extists
  if fileexists(dir .. "/" .. name .. dviext) then
    errorlevel = runcmd("dvipdfmx " .. name, dir, {})
  end
  return errorlevel
end

local function mkfmts(engines,dir)
  for _,engine in pairs(engines) do
    engine = string.gsub(engine,"latex$","tex")
    local ininame = string.gsub(engine,"tex$","latex.ini")
    if engine:match("u?ptex") then
      engine = "e" .. engine
    end
    print("Building format for " .. engine)
    local errorlevel = runcmd(engine .. " -etex -ini "
      .. " -no-guess-input-enc -kanji=utf8 "
      .. ininame .. " > " .. os_null, dir, {})
    if errorlevel ~= 0 then
      print("Failed building format for " .. engine)
      return errorlevel
    end
  end
  return 0
end

function checkinit_hook()
  local engines = options.engine
  if not engines then
    local target = options.target
    if target == 'check' or target == 'bundlecheck' then
      engines = checkengines
    elseif target == 'save' then
      engines = {stdengine}
    else
      error'Unexpected target in call to checkinit_hook'
    end
  end
  return mkfmts(engines, testdir)
end

function docinit_hook()
  return mkfmts({typesetexe},typesetdir)
end
