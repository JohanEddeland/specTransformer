function groundToSTL(obj, component)
%FUNCTION   Description goes here.
%

FPIstruct = struct();
FPIstruct.prereqSignals = {};
FPIstruct.prereqFormula = '';
FPIstruct.formula = '0';

% Create parameters to updateSubStructAndFormulaString
updateStruct = struct();
updateStruct.startDelay = 0;
updateStruct.endDelay = 0;
updateStruct.depth = 0;
updateStruct.modalDepth = 0;
updateStruct.type = 'signal_exp';
updateStruct.component = component;
updateStruct.str = obj.getStringWithFPI('0');
updateStruct.FPIstruct = FPIstruct;

obj.updateSubStructAndFormulaString(updateStruct);

end

