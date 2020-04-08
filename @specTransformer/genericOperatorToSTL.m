function genericOperatorToSTL(obj, component, componentStrings, type, operatorList)
%GENERICOPERATORTOSTL Summary of this function goes here
%   obj is the testronSTL object.
%   component is the handle to the current Simulink component.
%   componentStrings is a cell array telling how to apply the operator, for
%   example applying absolute value, componentStrings = {'abs(',')'}
%   operatorList is an OPTIONAL list of operators to apply, for example
%   '++-+' (must be of length equal to number of inputs)

inputNames = obj.getInputNames(component);

if exist('operatorList', 'var')
    % Make sure length of operatorList is equal to number of inputs
    assert(length(operatorList) == length(inputNames));
else
    operatorList = {};
end

if length(inputNames) == 1
    genericOneInputToSTL(obj, component, inputNames, componentStrings, type);
else
    genericNInputsToSTL(obj, component, inputNames, componentStrings, type, operatorList);
end

end

function genericOneInputToSTL(obj, component, inputNames, componentStrings, type)

% We should have exactly two componentStrings to use
assert(length(componentStrings) == 2);

compString1 = componentStrings{1};
compString2 = componentStrings{2};

[startDelay, endDelay, depth, modalDepth, FPIstruct] = obj.getSubStructInfo(inputNames{1});

for tmpIndex=1:length(FPIstruct)
    FPIstruct(tmpIndex).formula = [compString1 FPIstruct(tmpIndex).formula compString2];
end

% str is the formula
% delay is the same as for input
% depth is 1 more than input
% modal depth is the same as for input
updateStruct = struct();
updateStruct.startDelay = startDelay;
updateStruct.endDelay = endDelay;
updateStruct.depth = depth + 1;
updateStruct.modalDepth = modalDepth;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = type;
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

function genericNInputsToSTL(obj, component, inputNames, componentStrings, type, operatorList)

% componentStrings example: {'(', '==', ')'}
% We should have exactly three componentStrings to use
assert(length(componentStrings) == 3);

compString1 = componentStrings{1};
compString2 = componentStrings{2};
compString3 = componentStrings{3};

numOfPairs = length(inputNames)-1;

[~, ~, ~, ~, FPIstruct1, ~] = obj.getSubStructInfo(inputNames{1});
[~, ~, ~, ~, FPIstruct2, ~] = obj.getSubStructInfo(inputNames{2});


for nPairs = 1:numOfPairs
    FPIstruct = struct('prereqSignals', {},...
        'prereqFormula', {}, ...
        'formula', {});
    
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
            
            % If we have an operatorList to follow, update compString2 to
            % use the current operator instead!
            if ~isempty(operatorList)
                compString2 = operatorList(nPairs + 1);
            end
            
            FPIstruct(end).formula = [compString1 FPIstruct1(tmpIndex).formula ' ' compString2 ' ' FPIstruct2(tmpIndex2).formula compString3];
        end
    end
    
    try
        [~, ~, ~, ~, FPIstruct2] = obj.getSubStructInfo(inputNames{nPairs + 2});
        FPIstruct1 = FPIstruct;
    catch
    end
    %FPIstruct1(1) = [];
end
%FPIstruct(1) = [];

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
updateStruct.type = type;
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

