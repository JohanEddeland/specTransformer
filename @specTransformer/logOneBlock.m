function lastOutputSignalName = logOneBlock(obj, blockHandle)
blockName = get(blockHandle, 'Name');
blockName = regexprep(blockName,'\s+',' '); % Remove whitespaces from the blockName
blockName = blockName(~isspace(blockName));
blockName = strrep(blockName,'-',''); % Remove dashes in blockName (not valid variable name in MATLAB)
if ~isempty(regexp(blockName(1),'\d','ONCE'))
    % blockName starts with a digit
    % This is not a legal variable name in MATLAB
    % Add an 'A' at the beginning of the logged name to make it a legal
    % variable name in MATLAB
    blockName = ['A' blockName];
elseif strfind(blockName, '=')
    % '=' is not allowed in a variable name
    % Rename the signal
    blockName = 'LoggedBlock';
end
tmpPh = get(blockHandle,'PortHandles');
outportHandle = tmpPh.Outport;

if isempty(outportHandle)
    % There are no outputs from the block - there is nothing to log!!
    return
end

disp(['Logging output of ' blockName num2str(obj.logCounter)]);
tmpSignalName = [blockName num2str(obj.logCounter)];

% Store the block and data type 
IndexC = strfind(obj.allBlocks, [get(blockHandle, 'Path') '/' get(blockHandle, 'Name')]);
typeIndex = not(cellfun('isempty', IndexC));
obj.logBlocks = [obj.logBlocks; tmpSignalName];
obj.logTypes = [obj.logTypes; obj.allTypes{typeIndex}];

obj.logCounter = obj.logCounter + 1;
obj.fpiCounter = obj.fpiCounter + 1;
if length(outportHandle) > 1
    tmpSignalName2 = [blockName num2str(obj.logCounter)];
    %eval(['log' num2str(obj.logCounter) ' = tmpSignalName;']);
    obj.logCounter = obj.logCounter + 1;
    obj.fpiCounter = obj.fpiCounter + 1;
end

lastOutputSignalName = tmpSignalName;

set(outportHandle,'Name',tmpSignalName);
set_param(outportHandle(1),'DataLogging','on');
if length(outportHandle) > 1
    set(outportHandle,'Name',tmpSignalName2);
    set_param(outportHandle(2),'DataLogging','on');
end

obj.skippedString = [obj.skippedString '# ' tmpSignalName '\n'];
if length(outportHandle) > 1
    obj.skippedString = [obj.skippedString '# ' tmpSignalName2 '\n'];
end
end