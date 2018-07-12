function muxToSTL(obj, component)
%FUNCTION   Description goes here.
%

% Get the input names
inputNames = obj.getInputNames(component);

% Save in obj.muxSignals to be used when we come across a SUM block!
obj.muxSignals(obj.muxCounter).inputNames = inputNames;

% Now, the output of the mux is simply seen as a constant, i.e. the output
% of the Mux is "muxSignals"
FPIstruct = struct();
FPIstruct.prereqSignals = {};
FPIstruct.prereqFormula = '';
FPIstruct.formula = ['muxSignals' num2str(obj.muxCounter) '[t]'];

updateStruct = struct();
updateStruct.str = obj.getStringWithFPI(['muxSignals' num2str(obj.muxCounter) '[t]']);
updateStruct.startDelay = 0;
updateStruct.endDelay = 0;
updateStruct.depth = 0;
updateStruct.modalDepth = 0;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'signal_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

% Important: Increase the muxCounter by 1!
obj.muxCounter = obj.muxCounter + 1;

end

