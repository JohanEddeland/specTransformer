function relationalOperatorToSTL(obj, component)
%FUNCTION   Description goes here.
%

operator = get(component,'Operator');

% Get the input types of the relational operator - make sure they are of
% the same type (otherwise it makes no sense)
inputNames = obj.getInputNames(component);
inputType1 = obj.getType(inputNames{1});
inputType2 = obj.getType(inputNames{2});

% Initialize values to the flags indicating if inputs are logical
if strcmp(inputType1,'phi_exp') || strcmp(inputType2, 'phi_exp')
    % At least one input is logical!
    % We need to change to a logical formula to match STL semantics
    if strcmp(operator, '==')
        % Change formula to "(inp1 and inp2) or (not(inp1) and not(inp2))"
        andAsEqualityToSTL(obj, component, inputNames);
    elseif strcmp(operator, '~=')
        % Change formula to "(inp1 and not(inp2)) or (not(inp1) and inp2)"
        notAndAsEqualityToSTL(obj, component, inputNames);
    elseif strcmp(operator, '<=')
        % Change formula to "not(inp1) or inp2"
        componentStrings = {'(not(', ') or ', ')'};
        obj.genericOperatorToSTL(component, componentStrings, 'phi_exp');
    elseif strcmp(operator, '<')
        % Change formula to "not(inp1) and inp2"
        componentStrings = {'(not(', ') and ', ')'};
        obj.genericOperatorToSTL(component, componentStrings, 'phi_exp');
    elseif strcmp(operator, '>=')
        % Change formula to "inp1 or not(inp2)"
        componentStrings = {'(', ' or not(', '))'};
        obj.genericOperatorToSTL(component, componentStrings, 'phi_exp');
    elseif strcmp(operator, '>')
        % Change formula to "inp1 and not(inp2)"
        componentStrings = {'(', ' and not(', '))'};
        obj.genericOperatorToSTL(component, componentStrings, 'phi_exp');
    else
        error(['Undefined what to do when an input is logical for this operator: ' operator]);
    end
    
else
    % Assert that the inputs are of same type
    assert(strcmp(inputType1, 'signal_exp'));
    assert(strcmp(inputType2, 'signal_exp'));
    
    if strcmp(operator, '~=')
        componentStrings = {'not(', '==', ')'};
        obj.genericOperatorToSTL(component, componentStrings, 'phi_exp');
    else
        componentStrings = {'(', operator, ')'};
        obj.genericOperatorToSTL(component, componentStrings, 'phi_exp');
    end
end


end

function andAsEqualityToSTL(obj, component, inputNames)
% Formula to be implemented:
% (inp1 and inp2) or (not(inp1) and not(inp2))

% Based on genericNInputsToSTL, found in genericOperatorToSTL.m

numOfPairs = length(inputNames)-1;

[~, ~, ~, ~, FPIstruct1] = obj.getSubStructInfo(inputNames{1});
[~, ~, ~, ~, FPIstruct2] = obj.getSubStructInfo(inputNames{2});

FPIstruct = struct();
for nPairs = 1:numOfPairs

    for tmpIndex=1:length(FPIstruct1)
        for tmpIndex2=1:length(FPIstruct2)
            % Update prereqSignals
            if isempty(FPIstruct1(tmpIndex).prereqSignals) && ...
                    isempty(FPIstruct2(tmpIndex2).prereqSignals) && ...
                    length(FPIstruct) > 1
                % Empty prerequisites! We do not
                % need to add another instance to
                % FPIstruct
                FPIstruct(end).prereqSignals = {FPIstruct1(tmpIndex).prereqSignals{:}, FPIstruct2(tmpIndex2).prereqSignals{:}};
            else
                FPIstruct(end+1).prereqSignals = {FPIstruct1(tmpIndex).prereqSignals{:}, FPIstruct2(tmpIndex2).prereqSignals{:}}; %#ok<AGROW>
            end
            
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
            
            FPIstruct(end).formula = ['((' FPIstruct1(tmpIndex).formula ' and ' FPIstruct2(tmpIndex2).formula ') or (not(' FPIstruct1(tmpIndex).formula ') and not(' FPIstruct2(tmpIndex2).formula ')))'];
        end
    end
    
    try
        [~, ~, ~, ~, FPIstruct2] = obj.getSubStructInfo(inputNames{nPairs + 2});
        FPIstruct1 = FPIstruct;
        FPIstruct1(1) = [];
    catch
    end
end
FPIstruct(1) = [];

startDelayList = zeros(length(inputNames),1);
endDelayList = zeros(length(inputNames), 1);
depthList = zeros(length(inputNames),1);
modalDepthList = zeros(length(inputNames),1);
for nDelay = 1:length(inputNames)
    [startDelay, endDelay, depth, modalDepth, ~] = obj.getSubStructInfo(inputNames{nDelay});
    startDelayList(nDelay) = startDelay;
    endDelayList(nDelay) = endDelay;
    depthList(nDelay) = depth + 1;
    modalDepthList = modalDepth;
end

updateStruct = struct();
updateStruct.startDelay = max(startDelayList);
updateStruct.endDelay = max(endDelayList);
updateStruct.depth = max(depthList);
updateStruct.modalDepth = max(modalDepthList);
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

function notAndAsEqualityToSTL(obj, component, inputNames)
% Formula to be implemented:
% (inp1 and not(inp2)) or (not(inp1) and inp2)

% Based on genericNInputsToSTL, found in genericOperatorToSTL.m

numOfPairs = length(inputNames)-1;

[~, ~, ~, ~, FPIstruct1] = obj.getSubStructInfo(inputNames{1});
[~, ~, ~, ~, FPIstruct2] = obj.getSubStructInfo(inputNames{2});

FPIstruct = struct();
for nPairs = 1:numOfPairs

    for tmpIndex=1:length(FPIstruct1)
        for tmpIndex2=1:length(FPIstruct2)
            
            % Update prereqSignals
            if isempty(FPIstruct1(tmpIndex).prereqSignals) && ...
                    isempty(FPIstruct2(tmpIndex2).prereqSignals) && ...
                    length(FPIstruct) > 1
                % Empty prerequisites! We do not
                % need to add another instance to
                % FPIstruct
                FPIstruct(end).prereqSignals = {FPIstruct1(tmpIndex).prereqSignals{:}, FPIstruct2(tmpIndex2).prereqSignals{:}};
            else
                FPIstruct(end+1).prereqSignals = {FPIstruct1(tmpIndex).prereqSignals{:}, FPIstruct2(tmpIndex2).prereqSignals{:}}; %#ok<AGROW>
            end
            
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
            
            FPIstruct(end).formula = ['((' FPIstruct1(tmpIndex).formula ' and not(' FPIstruct2(tmpIndex2).formula ')) or (not(' FPIstruct1(tmpIndex).formula ') and ' FPIstruct2(tmpIndex2).formula '))'];
        end
    end
    
    try
        [~, ~, ~, ~, FPIstruct2] = obj.getSubStructInfo(inputNames{nPairs + 2});
        FPIstruct1 = FPIstruct;
        FPIstruct1(1) = [];
    catch
    end
end
FPIstruct(1) = [];

startDelayList = zeros(length(inputNames),1);
endDelayList = zeros(length(inputNames), 1);
depthList = zeros(length(inputNames),1);
modalDepthList = zeros(length(inputNames),1);
for nDelay = 1:length(inputNames)
    [startDelay, endDelay, depth, modalDepth, ~] = obj.getSubStructInfo(inputNames{nDelay});
    startDelayList(nDelay) = startDelay;
    endDelayList(nDelay) = endDelay;
    depthList(nDelay) = depth + 1;
    modalDepthList = modalDepth;
end

updateStruct = struct();
updateStruct.startDelay = max(startDelayList);
updateStruct.endDelay = max(endDelayList);
updateStruct.depth = max(depthList);
updateStruct.modalDepth = max(modalDepthList);
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end









