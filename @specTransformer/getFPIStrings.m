function [startStrings, endStrings] = getFPIStrings(inputString)
[startIndex,endIndex] = regexp(inputString,'{\d*}');

% startStrings contains strings like {1}, {2}, {3}
% endStrings contains strings like {/1}, {/2}, {/3}
startStrings = cell(1, length(startIndex));
endStrings = cell(1, length(startIndex));

for tmpIndex=1:length(startIndex)
    startStrings{tmpIndex} = inputString(startIndex(tmpIndex):endIndex(tmpIndex));
    endStrings{tmpIndex} = [inputString(startIndex(tmpIndex)) '/' inputString(startIndex(tmpIndex)+1:endIndex(tmpIndex))];
end

end