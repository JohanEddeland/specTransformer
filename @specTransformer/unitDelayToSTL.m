function unitDelayToSTL(obj, component)
%UNITDELAYTOSTL   Shifts the time backwards 1 timestep (= dt)
%   obj is the testronSTL object
%   component is a handle to the current block in the requirement model

inputName = obj.getInputNames(component);
[startDelay, endDelay, depth, modalDepth, FPIstruct, type] = obj.getSubStructInfo(inputName{1});

% Fix the FPIstruct
for k = 1:length(FPIstruct)
    for prereqCounter = 1:numel(FPIstruct(k).prereqSignals)
        FPIstruct(k).prereqSignals{prereqCounter} = ...
            obj.shiftTimeBackwards(FPIstruct(k).prereqSignals{prereqCounter}, '1');
    end
    FPIstruct(k).prereqFormula = obj.shiftTimeBackwards(FPIstruct(k).prereqFormula, '1');
    
    tmpFormula = FPIstruct(k).formula;
    % Handle the case where the formula is just 0 (for
    % example)
    if isa(tmpFormula,'double')
        tmpFormula = num2str(tmpFormula);
    end
    
    % Shift tmpFormula backwards by 1 time step
    tmpFormula = obj.shiftTimeBackwards(tmpFormula, '1');
    
    FPIstruct(k).formula = tmpFormula;
end

updateStruct = struct();
updateStruct.startDelay = startDelay + 1;
updateStruct.endDelay = endDelay;
updateStruct.depth = depth;
updateStruct.modalDepth = modalDepth;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = type;
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

