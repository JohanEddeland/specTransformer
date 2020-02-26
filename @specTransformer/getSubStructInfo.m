function [startDelay, endDelay, depth, modalDepth, FPIstruct, type] = getSubStructInfo(obj, str)
%GETSUBSTRUCTINFO Gets all subStruct info for a given sub-signal-name. 
%   str is a signal name, e.g. "sub56" or "sub118"

% Get the number of the sub-signal
[startIndex, endIndex] = regexp(str, '\d*');
digitAsString = str(startIndex:endIndex);
subIndex = str2double(digitAsString);

startDelay = obj.subStruct(subIndex).startDelay;
endDelay = obj.subStruct(subIndex).endDelay;
depth = obj.subStruct(subIndex).depth;
modalDepth = obj.subStruct(subIndex).modalDepth;
FPIstruct = obj.subStruct(subIndex).FPIstruct;
type = obj.subStruct(subIndex).type;

end

