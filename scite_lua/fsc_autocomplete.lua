local fsc = "scite_lua\\fsc\\fsautocomplete.exe"
local curr_file = ""
local spawner_obj = nil
local ready = false
local chunk_kind = ''
local curr_chunk = ''
local FSC_running = false
local _pos = 0

function ProcessChunk(s)
   local kind = string.match(s, '"Kind":"([^"]+)"')
   if kind == nil then -- cannot compare nil with string
       kind = ''
   end
   local dat = ''
   if ready and kind == "tooltip" then -- {"Kind":"tooltip","Data":"val c : int\n\nFull name: Smart_compl.c"}
      dat = string.match(s, '"Data":"([^\\^"]+)')
      scite.StripShow(" " .. dat)
      editor:CallTipShow(_pos, dat)
   elseif kind == "error" then --  {"Kind":"error","Data":"File 'smart_compl.fsx' not parsed"}
      dat = string.match(s, '"Data":([^]]+).')
   elseif kind == "errors" or chunk_kind == "errors" then --  {"Kind":"errors","Data":[{"FileName":"smart_compl.fsx","StartLine":10,"EndLine":10,"StartColumn":19,"EndColumn":21,"Severity":"Error","Message":"The value or constructor 'cg' is not defined","Subcategory":"typecheck"}]}
      chunk_kind = "errors"
      curr_chunk = curr_chunk .. s
      local indx = string.find(curr_chunk, ']')
      if indx ~= nil then
         local msg = string.match(curr_chunk, '"Severity":"Error","Message":"([^"]+)"')
         if msg == nil then
             ready = true
             print("Syntax OK")
             props['status.msg'] = "Ready | "
         else
            props['status.msg'] = "Syntax errors! | "
            for row1, row2, col1, col2, msg in string.gmatch(curr_chunk, '"StartLine":(%d+),"EndLine":(%d+),"StartColumn":(%d+),"EndColumn":(%d+),"Severity":"Error","Message":"([^"]+)"') do
               print('File "' .. curr_file .. '", line ' .. row1 .. ': ' .. msg)
               local pos = row1 and editor:PositionFromLine(row1 - 1) + col1 - 1
               editor.IndicatorCurrent = INDIC_SQUIGGLEPIXMAP
               editor.IndicFore[INDIC_SQUIGGLEPIXMAP] = 255
               editor:IndicatorFillRange(pos, col2 - col1)               
            end
         end
         scite.UpdateStatusBar(true)
         curr_chunk = ''
         chunk_kind = ''
      end
   elseif kind == "method" then
--~    {"Kind":"method","Data":{"Name":"f","CurrentParameter":0,"Overloads":[{"Tip":"val f : x:int -> float\n\n\n function f","TypeText":": float ","Parameters":[{"Name":"x","CanonicalTypeTextForSorting":"System.Int32","Display":"x: int","Description":""}],"IsSta
--~ ticArguments":false}]}}
      dat = string.match(s, '"Display":"([^"]+)"')
      editor:CallTipShow(_pos, dat)
   elseif kind == "info" then
      dat = string.match(s, '"Data":.([^"]+)')
      print(dat)
   elseif kind == "declarations" or chunk_kind == "declarations" then
  -- {"Kind":"declarations","Data":[{"Declaration":{"UniqueName":"Smart_compl_1_of_1","Name":"Smart_compl","Glyph":84,"Kind":{"Case":"ModuleFileDecl"},"Range":{"StartColumn":1,"StartLine":1,"EndColumn":20,"EndLine":10},"BodyRange":{"StartColumn":1,"StartLine":1
-- ,"EndColumn":17,"EndLine":8},"IsSingleTopLevel":true},"Nested":[{"UniqueName":"Smart_compl_1_of_1","Name":"f","Glyph":6,"Kind":{"Case":"FieldDecl"},"Range":{"StartColumn":5,"StartLine":7,"EndColumn":17,"EndLine":8},"BodyRange":{"StartColumn":5,"StartLine":7,"EndColumn":17,"EndLine":8},"IsSingleTopLevel":false}]}]}
      chunk_kind = "declarations"
      curr_chunk = curr_chunk .. s
      local indx = string.find(curr_chunk, ']')
      if indx ~= nil then
         local defs = {}
         for name, glyph in string.gmatch(curr_chunk, '"Name":"([^"]+)","Glyph":(%d+)') do
            print(name)
            table.insert(defs, name .. ", " .. glyph)
         end
         local list = table.concat(defs, ";")
         editor.AutoCSeparator = string.byte(';')
         editor:UserListShow(12, list)
         editor.AutoCSeparator = string.byte(' ')
         curr_chunk = ''
         chunk_kind = ''         
      end
   elseif kind == "finddecl" then
     -- {"Kind":"finddecl","Data":{"File":"smart_compl.fsx","Line":3,"Column":5}}
      row, col = string.match(s, '"Line":(%d+),"Column":(%d+)')
      editor:GotoLine(row - 1)
   elseif kind == "symboluse" or chunk_kind == "symboluse" then
--~ {"Kind":"symboluse","Data":{"Name":"c","Uses":[{"FileName":"D:\\wscite\\scite_lua\\smart_compl.fsx","StartLine":3,"StartColumn":5,"EndLine":3,"EndColumn":6,"IsFromDefinition":true,"IsFromAttribute":false,"IsFromComputationExpression":false,"IsFromDispatchS
--~ lotImplementation":false,"IsFromPattern":false,"IsFromType":false},{"FileName":"D:\\wscite\\scite_lua\\smart_compl.fsx","StartLine":11,"StartColumn":19,"EndLine":11,"EndColumn":20,"IsFromDefinition":false,"IsFromAttribute":false,"IsFromComputationExpression":false,"IsFromDispatchSlotImplementation":false,"IsFromPattern":false,"IsFromType":false}]}}      
      chunk_kind = "symboluse"
      curr_chunk = curr_chunk .. s
      local indx = string.find(curr_chunk, ']')
      if indx ~= nil then
         local uses = {}
         for row, col in string.gmatch(s, '"StartLine":(%d+),"StartColumn":(%d+)') do
            print(curr_file .. ':' .. row .. ':')
            table.insert(uses, name .. ": " .. row .. ", " .. col)
         end
         local list = table.concat(uses, ";")
         editor.AutoCSeparator = string.byte(';')
         editor:UserListShow(12, list)
         editor.AutoCSeparator = string.byte(' ')
         curr_chunk = ''
         chunk_kind = ''         
      end
   end
end

function ProcessResult(res)
	print("Result: " .. res)
end

function Start_FSC()
   if FSC_running then
      print("Already running")
      return true
   end
   props['status.msg'] = "Start | "
   scite.UpdateStatusBar(true)
   if props['dwell.period'] == '' then
      props['dwell.period'] = 500
   end
   spawner.verbose(true)
   spawner.fulllines(1)
   spawner_obj = spawner.new(fsc)
   spawner_obj:set_output('ProcessChunk')
--~    spawner_obj:set_result('ProcessResult')
   FSC_running = spawner_obj:run()   
   if not FSC_running then
      props['status.msg'] = "ERROR"
   else
      props['status.msg'] = "Parsing | "
   end
   scite.UpdateStatusBar()
   return FSC_running
end

function ParseFile(file)
   local ext = file:match("^.+(%..+)$")
   if ext == ".fsx" then
      if spawner_obj == nil then
         Start_FSC()
      end
      editor:IndicatorClearRange(0, editor.Length)
      curr_file = file
      f = io.open(file, "r")
      text = f:read("*a")
	   print("Parsing " .. curr_file)
      local cmd = string.format("parse \"%s\"\n%s\n<<EOF>>\n", curr_file, text)
      spawner_obj:write(cmd)
   end
end

function columnOfPosition(position)
    local line = editor:LineFromPosition(position)
    local oldposition = editor.CurrentPos
    local column = 0
    editor:GotoPos(position)
    while editor.CurrentPos ~= 0 and line == editor:LineFromPosition(editor.CurrentPos) do
        editor:CharLeft()
        column = column + 1
    end
    editor:GotoPos(oldposition)
    if line > 0 then
        return column - 1
    else
        return column
    end

end

function launch_cmd(cmd, word, row_col)
   if curr_file == "" then
      curr_file = scite_CurrentFile()
      ParseFile(curr_file)
   end
   if row_col then
      local row = editor:LineFromPosition(editor.CurrentPos) + 1
      local col =  columnOfPosition(editor.CurrentPos) + 1
      cmd = string.format("%s \"%s\" %d %d 400\n", cmd, curr_file, row, col)
   else
      if word == "" then
         cmd = string.format("%s \"%s\" 400\n", cmd, curr_file)
      else
         cmd = string.format("%s \"%s\"\n", cmd, word)
      end
   end
--~    print(cmd)
   spawner_obj:write(cmd)
end

function Complete_FSC()
   launch_cmd("completion", "", true)
end

function Declarations_FSC()
   launch_cmd("declarations", "", false)
end

function Find_FSC()
   launch_cmd("finddecl", "", true)
end

function Use_FSC()
   launch_cmd("symboluse", "", true)
end

function Methods_FSC()
   launch_cmd("methods", "", true)
end

function Quit_FSC()
    if not FSC_running or spawner_obj == nil then
        print('FSC is not running')
    else
        spawner_obj:write('quit\n')
        spawner_obj:close()
        FSC_running = false
        props['status.msg'] = "Stopped"
        scite.UpdateStatusBar(true)
    end
end

-- used to pick up current expression from current document position
-- We use the selection, if available, and otherwise pick up the word.
local function current_expr()
    local s = editor:GetSelText()
    if s == '' then -- no selection, so find the word
        pos = editor.CurrentPos
        local p1 = editor:WordStartPosition(pos, true)
        local p2 = editor:WordEndPosition(pos, true)
        s = editor:textrange(p1, p2)
	 end
    return s
end

function HelpText_FSC()
   launch_cmd("helptext", current_expr(), false)
end

function Signature_FSC()
   launch_cmd("tooltip", "", true)
end

function Restart_FSC()
   Quit_FSC()
   Start_FSC()
end

-- *doc* if your scite has OnDwellStart, then the current symbol under the mouse
-- pointer will be evaluated and shown in a calltip.
scite_OnDwellStart(
   function (pos, s)
     if FSC_running then
        if s ~= '' then
            -- s = current_expr(pos)
            _pos = pos
            Signature_FSC()
        else
           editor:CallTipCancel()
        end
     end
     return true
   end
)

SetCommand('Complete', 'Complete_FSC', '*.fsx;*.fs', 'Alt+C')
SetCommand('Restart', 'Restart_FSC', '*.fsx;*.fs', 'Alt+R')
SetCommand('Type signature', 'Signature_FSC', '*.fsx;*.fs', 'Alt+T')
SetCommand('Declarations', 'Declarations_FSC', '*.fsx;*.fs', 'Alt+D')
SetCommand('Find declaration', 'Find_FSC', '*.fsx;*.fs', 'Alt+F')
SetCommand('Symbol usage', 'Use_FSC', '*.fsx;*.fs', 'Alt+U')
SetCommand('Help text', 'HelpText_FSC', '*.fsx;*.fs', 'Alt+H')
SetCommand('Methods', 'Methods_FSC', '*.fsx;*.fs', 'Alt+M')
SetCommand('Quit', 'Quit_FSC', '*.fsx;*.fs', 'Alt+Q')

scite_OnSave(ParseFile)
