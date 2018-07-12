function inportToSTL(obj, component)
%FUNCTION   Description goes here.
%

blockValue = get(component,'Name');

FPIstruct = struct();
FPIstruct.prereqSignals = {};
FPIstruct.prereqFormula = '';
FPIstruct.formula = [blockValue '[t]'];
str = obj.getStringWithFPI([blockValue '[t]']);

updateStruct = struct();
updateStruct.str = str;
updateStruct.startDelay = 0;
updateStruct.endDelay = 0;
updateStruct.depth = 0;
updateStruct.modalDepth = 0;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'signal_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

