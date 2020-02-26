function detectDecreaseToSTL(obj, component)
%FUNCTION   Description goes here.
%

% If input is a signal_exp:
% phi := inp[t] < inp[t-1]
% This is how it's implemented in the Simulink
% blocks, HOWEVER this only works if inp is a
% signal expression (see STL_Formula grammar, "<"
% can only be used between signal expressions)

% If input is a phi_exp:
% phi := not(inp[t]) and inp[t-1]
% This formula works if inp is an STL Formula!
% (phi_expr in STL_Formula grammar definition)

inputNames = obj.getInputNames(component);
[startDelay, endDelay, depth, modalDepth, FPIstruct, inputType] = obj.getSubStructInfo(inputNames{1});

if strcmp(inputType,'phi_exp')
    
    for tmpIndex=1:length(FPIstruct)
        % term1 = inp[t]
        term1 = FPIstruct(tmpIndex).formula;
        % term2 = inp[t-1]
        term2 = obj.shiftTimeBackwards(term1,'1');
        
        FPIstruct(tmpIndex).formula = ['not(' term1 ') and ' term2];
    end
    
    updateStruct = struct();
    updateStruct.startDelay = startDelay + 1;
    updateStruct.endDelay = endDelay;
    updateStruct.depth = depth + 2;
    updateStruct.modalDepth = modalDepth;
    updateStruct.FPIstruct = FPIstruct;
    updateStruct.type = 'phi_exp';
    updateStruct.component = component;
    
    obj.updateSubStructAndFormulaString(updateStruct);
else
    
    for tmpIndex=1:length(FPIstruct)
        % term1 = inp[t]
        term1 = FPIstruct(tmpIndex).formula;
        % term2 = inp[t-1]
        term2 = obj.shiftTimeBackwards(term1, '1');
        
        FPIstruct(tmpIndex).formula = [term1 ' < ' term2];
    end
    
    updateStruct = struct();
    updateStruct.startDelay = startDelay + 1;
    updateStruct.endDelay = endDelay;
    updateStruct.depth = depth + 2;
    updateStruct.modalDepth = modalDepth;
    updateStruct.FPIstruct = FPIstruct;
    updateStruct.type = 'phi_exp';
    updateStruct.component = component;
    
    obj.updateSubStructAndFormulaString(updateStruct);
end

end

