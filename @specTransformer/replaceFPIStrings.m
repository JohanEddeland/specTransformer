function newInputString = replaceFPIStrings(obj, inputString)
% Replace all start strings ({1}, {2}, {3} etc) and
% end strings ({/1}, {/2}, {/3} etc)
[startIndex, ~] = regexp(inputString,'{\d*}');
idxLength = length(startIndex);
if idxLength>1000
    h = waitbar(0,['Replacing ' num2str(idxLength) ' placeholder strings ...'],'Name','Replacing placeholder strings');
end
for idx=1:idxLength
    
    [startIndex, endIndex] = regexp(inputString,'{\d*}');
    if idx > length(startIndex)
        break
    end
    inputString = strrep(inputString,inputString(startIndex(idx):endIndex(idx)),['{' num2str(obj.fpiCounter) '}']);
    [startIndex2, endIndex2] = regexp(inputString, '{/\d*}');
    if idx > length(startIndex2)
        break
    end
    inputString = strrep(inputString, inputString(startIndex2(idx):endIndex2(idx)),['{/' num2str(obj.fpiCounter) '}']);
    obj.fpiCounter = obj.fpiCounter + 1;
    
    if idxLength>1000
        waitbar(idx / idxLength);
    end
end

if idxLength>1000
    close(h);
end
newInputString = inputString;

end