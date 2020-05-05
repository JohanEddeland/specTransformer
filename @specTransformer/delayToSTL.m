function delayToSTL(obj, component)
%FUNCTION   Description goes here.

delayLength = get(component,'DelayLength');

inputNames = obj.getInputNames(component);
[startDelay, endDelay, depth, modalDepth, FPIstruct, type] = obj.getSubStructInfo(inputNames{1});

for k = 1:length(FPIstruct)
    for prereqCounter = 1:numel(FPIstruct(k).prereqSignals)
        FPIstruct(k).prereqSignals{prereqCounter} = ...
            obj.shiftTimeBackwards(FPIstruct(k).prereqSignals{prereqCounter}, delayLength);
    end
    FPIstruct(k).prereqFormula = obj.shiftTimeBackwards(FPIstruct(k).prereqFormula, delayLength);
    FPIstruct(k).formula = obj.shiftTimeBackwards(FPIstruct(k).formula, delayLength);
end

updateStruct = struct();
updateStruct.startDelay = startDelay + delayLength;
updateStruct.endDelay = endDelay;
updateStruct.depth = depth;
updateStruct.modalDepth = modalDepth;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = type;
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

