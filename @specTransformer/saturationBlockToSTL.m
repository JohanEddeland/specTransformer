function saturationBlockToSTL(obj, component)
%SATURATIONTOSTL   This creates an STL formula for the block called
%Saturation! 
%

inputNames = obj.getInputNames(component);
if length(inputNames) == 1
    % Only one input to the Saturation block
    [str, startDelay, endDelay, depth, modalDepth, FPIstruct] = obj.getSubStructInfo(inputNames{1});
elseif length(inputNames) == 3
    % 3 inputs to the saturation block
    % First input is minimum
    % Second input is the actual input to the saturation block
    % Third input is the maximum
    [str, startDelay, endDelay, depth, modalDepth, FPIstruct] = obj.getSubStructInfo(inputNames{2});
else
    % If we don't have 1 or 3 inputs, unsure what exactly we should do
    error('Unknown behaviour of Saturation when number of inputs is not 1 or 3');
end


[startStrings, endStrings]=obj.getFPIStrings(str);

lowerLimit = get(component, 'LowerLimit');
upperLimit = get(component, 'UpperLimit');

for tmpIndex=1:length(startStrings)
    startOfFirst = strfind(str,startStrings{tmpIndex});
    endOfFirst = startOfFirst + length(startStrings{tmpIndex});
    startOfNext = strfind(str,endStrings{tmpIndex});
    FPIstruct(tmpIndex).formula = ['min(' num2str(upperLimit) ', max(' num2str(lowerLimit) ', ' str(endOfFirst:startOfNext-1) '))'];
    str = [str(1:endOfFirst-1) 'min(' num2str(upperLimit) ', max(' num2str(lowerLimit) ', ' str(endOfFirst:startOfNext-1) '))' str(startOfNext:end)];
end

updateStruct = struct();
updateStruct.str = str;
updateStruct.startDelay = startDelay;
updateStruct.endDelay = endDelay;
updateStruct.depth = depth + 1;
updateStruct.modalDepth = modalDepth;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'signal_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

