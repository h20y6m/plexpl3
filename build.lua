module = "plexpl3"
bundle = ""

maindir = "."

os.setenv("guess_input_kanji_encoding", "0")

checkengines = {"ptex-euc","ptex-sjis","uptex","uptex-euc","uptex-sjis"}
stdengine    = "ptex-euc"
checkformat  = "latex"
checkopts    = " -interaction=nonstopmode -halt-on-error -kanji=utf8 "

specialformats = specialformats or {}
specialformats.latex = {
  ["ptex-euc"] = {
    binary  = "eptex",
    format  = "platex-euc",
    options = " -kanji-internal=euc " .. checkopts,
    ini     = "platex.ini",
  },
  ["ptex-sjis"] = {
    binary  = "eptex",
    format  = "platex-sjis",
    options = " -kanji-internal=sjis " .. checkopts,
    ini     = "platex.ini",
  },
  ["uptex"] = {
    binary  = "euptex",
    format  = "uplatex",
    options = " -kanji-internal=uptex " .. checkopts,
    ini     = "uplatex.ini",
  },
  ["uptex-euc"] = {
    binary  = "euptex",
    format  = "uplatex-euc",
    options = " -kanji-internal=euc " .. checkopts,
    ini     = "platex.ini",
  },
  ["uptex-sjis"] = {
    binary  = "euptex",
    format  = "uplatex-sjis",
    options = " -kanji-internal=sjis " .. checkopts,
    ini     = "platex.ini",
  },
}

installfiles = {"plexpl3.ltx","plexpl3.sty","plpatch3.sty"}

typesetexe  = "platex"
typesetopts = " -interaction=nonstopmode -halt-on-error -kanji=utf8 "

unpackexe  = "ptex"
unpackopts = " -interaction=batchmode -halt-on-error -kanji=utf8 "

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
    local binary = string.gsub(engine,"latex$","tex")
    local format = string.gsub(binary,"tex$","latex")
    local options = ""
    local ini = format .. ".ini"
    if binary:match("u?ptex") then
      binary = "e" .. binary
    end
    local special_check = specialformats[checkformat]
    if special_check and next(special_check) then
      engine_info = special_check[engine]
      if engine_info then
        binary = engine_info.binary or binary
        format = engine_info.format or format
        options = engine_info.options or options
        ini = engine_info.ini or ini
      end
    end
    print("Building format for " .. engine)
    local errorlevel = run(
      dir,
      os_setenv .. " TEXINPUTS=." .. localtexmf() .. os_pathsep
        .. os_concat ..
      binary .. " -etex -ini"
        .. " -jobname=" .. format
        .. " " .. options .. " -halt-on-error -kanji=utf8"
        .. " " .. ini .. " > " .. os_null
    )
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
