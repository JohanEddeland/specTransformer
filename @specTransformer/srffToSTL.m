function srffToSTL(obj, component)

% Output: Q[t] = (not R[t]) and (S[t] or Q[t-dt])

inputNames = obj.getInputNames(component);
[startDelay1, endDelay1, depth1, modalDepth1, FPIstruct1] = obj.getSubStructInfo(inputNames{1}); % s
[startDelay2, endDelay2, depth2, modalDepth2, FPIstruct2] = obj.getSubStructInfo(inputNames{2}); % r

% The new FPI struct will have the same prerequisites as R (input 2), but
% we will change the formula to also include "and once(S)"
newFPIstruct = struct();

% Keep track of if we have logged the delay block or not
% (We need to log it if R ~= 0 for any entry in FPIstruct)
% See details below
delayBlockLogged = 0;

% Keep track of if at least one R == 0
atLeastOneRZero = 0;

% NEW, WITH WRAP-UP
for tmpIndex2=1:length(FPIstruct2)
    % There are two different cases for each entry in the FPIstruct
    % 1. If R == 0, the formula is essentially once(S) over the whole
    %    simulation
    % 2. If R ~= 0, we cannot express the formula in STL. We would need
    %    something like STL*, since the formula is something like
    %    not(R[t]) and once_[0, t*](S[t])
    %    where t* is the time since R was last true. 
    
    % This means that if R ~= 0, we simply have to log the output of the
    % delay block and write the formula with respect to that.
    term2 = FPIstruct2(tmpIndex2).formula;
    try
        term2_evaluated = eval(term2);
    catch
        term2_evaluated = 1;
    end
    
    if term2_evaluated == 0
        % innerFormula is essentially "once_[0, endTime](S)", where S is the
        % first input. However, if S has multiple FPI struct entries, we need
        % to take care of that manually with the following for-loops.
        innerFormula = ['once_[0, ' num2str(obj.endTime) ']('];
        
        for tmpIndex1=1:length(FPIstruct1)-1
            innerFormula = [innerFormula '(' FPIstruct1(tmpIndex1).prereqFormula ' and ' FPIstruct(tmpIndex1).formula ') or']; %#ok<*AGROW>
        end
        
        if length(FPIstruct1) == 1
            innerFormula = [innerFormula FPIstruct1(end).formula];
        else
            innerFormula = [innerFormula '(' FPIstruct1(end).prereqFormula ' and ' FPIstruct1(end).formula ')'];
        end
        innerFormula = [innerFormula ')'];
        
        % Add a new entry to newFPIstruct
        newFPIstruct(end+1).prereqSignals = FPIstruct2(tmpIndex2).prereqSignals;
        newFPIstruct(end).prereqFormula = FPIstruct2(tmpIndex2).prereqFormula;
        newFPIstruct(end).formula = ...
            ['(not(' FPIstruct2(tmpIndex2).formula ') and ' ...
                innerFormula ')'];
            
        % At least one R is zero
        atLeastOneRZero = 1;
        
    else
        % R != 0
        % Formula: (not(R[t]) and (S[t] or Q[t-1]))
        
        % Check if we need to log the delay block, or if it has already
        % been done
        if ~delayBlockLogged
            delayBlock = find_system([get(component,'Path') '/' get(component,'Name')],'LookUnderMasks','On','FollowLinks','On','BlockType','UnitDelay');
            delayBlock = delayBlock{1};
            delayBlockHandle = get_param(delayBlock, 'Handle');
            
            % Log the delay block (it is used in the
            logSigName = obj.logOneBlock(delayBlockHandle);
            
            % We use Q to write the formula in a more readable form
            Q = [logSigName '[t]'];
            
            % Finally, now we note that we HAVE logged the delay block
            delayBlockLogged = 1;
        end
        
        % Create the actual formula
        for tmpIndex1=1:length(FPIstruct1)
            % Update prereqSignals
            newFPIstruct(end+1).prereqSignals = {FPIstruct1(tmpIndex1).prereqSignals{:}, FPIstruct2(tmpIndex2).prereqSignals{:}};
            
            % Update prereqFormula
            if isempty(FPIstruct1(tmpIndex1).prereqFormula)
                if isempty(FPIstruct2(tmpIndex2).prereqFormula)
                    newFPIstruct(end).prereqFormula = '';
                else
                    newFPIstruct(end).prereqFormula = FPIstruct2(tmpIndex2).prereqFormula;
                end
            else
                if isempty(FPIstruct2(tmpIndex2).prereqFormula)
                    newFPIstruct(end).prereqFormula = FPIstruct1(tmpIndex1).prereqFormula;
                else
                    newFPIstruct(end).prereqFormula = [FPIstruct1(tmpIndex1).prereqFormula ' and ' FPIstruct2(tmpIndex2).prereqFormula];
                end
            end
            
            % Update formula
            newFPIstruct(end).formula = ['(not(' term2 ') and (' ...
                FPIstruct1(tmpIndex1).formula ' or ' Q '))'];
        end
    end
end

% Remove the first empty entry in the newFPIstruct
newFPIstruct(1) = [];

thisStartDelay = max(startDelay1, startDelay2);
thisEndDelay = max(endDelay1, endDelay2);
thisDepth = max(depth1 + 2, depth2 + 2);
if atLeastOneRZero
    % At least one R is zero
    % Modal depth is increased
    thisModalDepth = max(modalDepth1 + 1, modalDepth2);
else
    thisModalDepth = max(modalDepth1, modalDepth2);
end

updateStruct = struct();
updateStruct.startDelay = thisStartDelay;
updateStruct.endDelay = thisEndDelay;
updateStruct.depth = thisDepth;
updateStruct.modalDepth = thisModalDepth;
updateStruct.FPIstruct = newFPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

