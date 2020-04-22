function notAlwaysToSTL(obj, component)
inputNames = obj.getInputNames(component);
[~, ~, ~, ~, FPIstruct1] = obj.getSubStructInfo(inputNames{1});
[~, ~, ~, ~, FPIstruct2] = obj.getSubStructInfo(inputNames{2});
[startDelay3, endDelay3, depth3, modalDepth3, FPIstruct] = obj.getSubStructInfo(inputNames{3});

% There are 3 inputs to notAlways:
% - 1: reqModelStepTime
% - 2: TqReqTimeOutTtol
% - 3: Input
steptime = evalin('base',FPIstruct1(1).formula);
assert(numel(FPIstruct1) == 1, 'We expect a constant as the duration to notAlwaysToSTL');

reqtime = evalin('base',FPIstruct2(1).formula);
assert(numel(FPIstruct2) == 1, 'We expect a constant as the steptime to notAlwaysToSTL');

% Calculate the time tolerance
timeTol = reqtime/steptime;

% In case the time tolerance is not an integer, it should be rounded down 
% to be equivalent to Simulink semantics of notAlways block
timeTol = floor(timeTol);

for tmpIndex=1:length(FPIstruct)
    % New implementation using past operators
    FPIstruct(tmpIndex).formula = ['(not(hist_[0, ' num2str(timeTol) '*dt](' FPIstruct(tmpIndex).formula ')))'];
end

updateStruct = struct();
updateStruct.startDelay = startDelay3 + timeTol;
updateStruct.endDelay = endDelay3;
updateStruct.depth = depth3 + 2;
updateStruct.modalDepth = modalDepth3 + 1;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct)

end

