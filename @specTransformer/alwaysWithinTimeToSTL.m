function alwaysWithinTimeToSTL(obj, component)
%FUNCTION   Description goes here.
%

inputNames = obj.getInputNames(component);
[startDelay, endDelay, depth, modalDepth, FPIstruct, ~] = obj.getSubStructInfo(inputNames{1});
[~, ~, ~, ~, FPIstruct2, ~] = obj.getSubStructInfo(inputNames{2});
[~, ~, ~, ~, FPIstruct3, ~] = obj.getSubStructInfo(inputNames{3});

startTime = evalin('base',FPIstruct2(1).formula);
assert(numel(FPIstruct2) == 1, 'We expect a constant as the startTime to alwaysWithinTimeToSTL');

endTime = evalin('base',FPIstruct3(1).formula);
assert(numel(FPIstruct3) == 1, 'We expect a constant as the endTime to alwaysWithinTimeToSTL');

assert(endTime > startTime, 'endTime must be larger than startTime. Are the inputs in the wrong order?');

for tmpIndex=1:length(FPIstruct)
    inp1 = FPIstruct(tmpIndex).formula;
    % Future version (alw_[startTime, endTime](input))
    FPIstruct(tmpIndex).formula = ['(alw_[' num2str(startTime) ', ' num2str(endTime) '](' inp1 '))']; %#ok<*AGROW>
    
    % Past version (hist_[obj.endTime - endTime, obj.endTime - startTime](input)
    % FPIstruct(tmpIndex).formula = ['(hist_[' num2str(obj.endTime - endTime) ', ' num2str(obj.endTime - startTime) '](' inp1 '))']; %#ok<*AGROW>
end

updateStruct = struct();
updateStruct.startDelay = startDelay + endTime;
updateStruct.endDelay = endDelay;
updateStruct.depth = depth + 1;
updateStruct.modalDepth = modalDepth + 1;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct)

end

