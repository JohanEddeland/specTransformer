function srffToSTL(obj, component)

% Output: Q[t] = (not R[t]) and (S[t] or Q[t-dt])

inputNames = obj.getInputNames(component);
[startDelay1, endDelay1, depth1, modalDepth1, FPIstruct1] = obj.getSubStructInfo(inputNames{1}); % s
[startDelay2, endDelay2, depth2, modalDepth2, FPIstruct2] = obj.getSubStructInfo(inputNames{2}); % r

% Now, find the delay block in the subsystem
delayBlock = find_system([get(component,'Path') '/' get(component,'Name')],'LookUnderMasks','On','FollowLinks','On','BlockType','UnitDelay');
delayBlock = delayBlock{1};
delayBlockHandle = get_param(delayBlock, 'Handle');

% Log the delay block (it is used in the 
logSigName = obj.logOneBlock(delayBlockHandle);

% We use Q to write the formula in a more readable form
Q = [logSigName '[t]'];

FPIstruct = struct();

for tmpIndex=1:length(FPIstruct1)
    term1 = FPIstruct1(tmpIndex).formula;
    
    for tmpIndex2=1:length(FPIstruct2)
        term2 = FPIstruct2(tmpIndex2).formula;
        
        FPIstruct(end+1).prereqSignals = {FPIstruct1(tmpIndex).prereqSignals{:}, FPIstruct2(tmpIndex2).prereqSignals{:}}; %#ok<AGROW>
        
        % Update prereqFormula
        if isempty(FPIstruct1(tmpIndex).prereqFormula)
            if isempty(FPIstruct2(tmpIndex2).prereqFormula)
                FPIstruct(end).prereqFormula = '';
            else
                FPIstruct(end).prereqFormula = FPIstruct2(tmpIndex2).prereqFormula;
            end
        else
            if isempty(FPIstruct2(tmpIndex2).prereqFormula)
                FPIstruct(end).prereqFormula = FPIstruct1(tmpIndex).prereqFormula;
            else
                FPIstruct(end).prereqFormula = [FPIstruct1(tmpIndex).prereqFormula ' and ' FPIstruct2(tmpIndex2).prereqFormula];
            end
        end
        
        try
            term2_evaluated = eval(term2);
        catch
            term2_evaluated = 1;
        end
        
        if term2_evaluated == 0
            % If R == 0, set the formula to the
            % following: (S[t] or Q[t-1])
            % Note that the signal we have logged as Q is indeed a
            % time-delayed signal, so we need not shift it backwards in
            % time
            FPIstruct(end).formula = ['(' term1 ' or ' Q ')'];
        else
            % R != 0
            % Formula: (not(R[t]) and (S[t] or Q[t-1]))
            FPIstruct(end).formula = ['(not(' term2 ') and (' term1 ' or ' Q '))'];
        end
    end
end
FPIstruct(1) = [];

thisStartDelay = max(startDelay1 + 1, startDelay2 + 1);
thisEndDelay = max(endDelay1, endDelay2);
thisDepth = max(depth1 + 2, depth2 + 2);
thisModalDepth = max(modalDepth1 + 1, modalDepth2 + 1);

updateStruct = struct();
updateStruct.startDelay = thisStartDelay;
updateStruct.endDelay = thisEndDelay;
updateStruct.depth = thisDepth;
updateStruct.modalDepth = thisModalDepth;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

