function switchToSTL(obj, component)
%FUNCTION   Description goes here.
%

inputNames = obj.getInputNames(component);

[startDelay1, endDelay1, depth1, modalDepth1, FPIstruct1, type1] = obj.getSubStructInfo(inputNames{1});
[startDelay2, endDelay2, depth2, modalDepth2, FPIstruct2, type2] = obj.getSubStructInfo(inputNames{2});
[startDelay3, endDelay3, depth3, modalDepth3, FPIstruct3, type3] = obj.getSubStructInfo(inputNames{3});

% Inputs 1 and 3 should be of the same type (otherwise, how do we know how
% to apply further operators to them?)
if ~strcmp(type1, type3)
    % Types are not the same
    % Enforce them to both be 'phi_exp', since we convert all signal_exp to
    % phi_exp at the end (the signal_exp 's' will be 'not(s == 0)'
    type1 = 'phi_exp';
    type3 = 'phi_exp';
end

thisFPIstruct = struct();

for tmpIndex=1:length(FPIstruct2)
    
    % First, add data for when inp2 ~= 0
    for kInp1=1:length(FPIstruct1)
        % Update prereqSignals
        if isempty(FPIstruct2(tmpIndex).prereqSignals)
            thisFPIstruct(end+1).prereqSignals = {[inputNames{2} ' ~= 0'],FPIstruct1(kInp1).prereqSignals{:}}; %#ok<*AGROW>
        else
            thisFPIstruct(end+1).prereqSignals = {FPIstruct2(tmpIndex).prereqSignals{:}, [inputNames{2} '~=0'],FPIstruct1(kInp1).prereqSignals{:}};
        end
        
        % Update prereqFormula
        if isempty(FPIstruct1(kInp1).prereqFormula)
            if isempty(FPIstruct2(tmpIndex).prereqFormula)
                thisFPIstruct(end).prereqFormula = [FPIstruct2(tmpIndex).formula];
            else
                thisFPIstruct(end).prereqFormula = [FPIstruct2(tmpIndex).prereqFormula ' and ' FPIstruct2(tmpIndex).formula];
            end
        else
            if isempty(FPIstruct2(tmpIndex).prereqFormula)
                thisFPIstruct(end).prereqFormula = [FPIstruct2(tmpIndex).formula ' and ' FPIstruct1(kInp1).prereqFormula];
            else
                thisFPIstruct(end).prereqFormula = [FPIstruct2(tmpIndex).prereqFormula ' and ' FPIstruct2(tmpIndex).formula ' and ' FPIstruct1(kInp1).prereqFormula];
            end
        end
        
        thisFPIstruct(end).formula = FPIstruct1(kInp1).formula;
    end
    
    % Then, add data for when inp2 == 0
    for kInp3=1:length(FPIstruct3)
        % Update prereqSignals
        if isempty(FPIstruct2(tmpIndex).prereqSignals)
            thisFPIstruct(end+1).prereqSignals = {[inputNames{2} ' == 0'],FPIstruct3(kInp3).prereqSignals{:}};
        else
            thisFPIstruct(end+1).prereqSignals = {FPIstruct2(tmpIndex).prereqSignals{:}, [inputNames{2} '==0'],FPIstruct3(kInp3).prereqSignals{:}};
        end
        
        % Update prereqFormula
        if isempty(FPIstruct3(kInp3).prereqFormula)
            if isempty(FPIstruct2(tmpIndex).prereqFormula)
                thisFPIstruct(end).prereqFormula = ['not(' FPIstruct2(tmpIndex).formula ')'];
            else
                thisFPIstruct(end).prereqFormula = [FPIstruct2(tmpIndex).prereqFormula ' and not(' FPIstruct2(tmpIndex).formula ')'];
            end
        else
            if isempty(FPIstruct2(tmpIndex).prereqFormula)
                thisFPIstruct(end).prereqFormula = ['not(' FPIstruct2(tmpIndex).formula ') and ' FPIstruct3(kInp3).prereqFormula];
            else
                thisFPIstruct(end).prereqFormula = [FPIstruct2(tmpIndex).prereqFormula ' and not(' FPIstruct2(tmpIndex).formula ') and ' FPIstruct3(kInp3).prereqFormula];
            end
        end
        
        thisFPIstruct(end).formula = FPIstruct3(kInp3).formula;
    end
    
end
thisFPIstruct(1) = [];

thisStartDelay = max([startDelay1, startDelay2, startDelay3]);
thisEndDelay = max([endDelay1, endDelay2, endDelay3]);
thisDepth = max([depth1, depth2, depth3]) + 2;
thisModalDepth = max([modalDepth1, modalDepth2, modalDepth3]);

updateStruct = struct();
updateStruct.startDelay = thisStartDelay;
updateStruct.endDelay = thisEndDelay;
updateStruct.depth = thisDepth;
updateStruct.modalDepth = thisModalDepth;
updateStruct.FPIstruct = thisFPIstruct;
updateStruct.type = type1; % Remember: type1 is equal to type 3
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

