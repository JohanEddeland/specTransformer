function multiPortSwitchToSTL(obj, component)
%FUNCTION   Description goes here.
%

inputNames = obj.getInputNames(component);

[str, ~, ~, ~,  ~, FPIstruct] = obj.getSubStructInfo(inputNames{1});

str = obj.replaceFPIStrings(str);
[startStrings, endStrings] = obj.getFPIStrings(str);

% Get the data port indices
indices = get(component,'DataPortIndices');
indices = strrep(indices,' ','');
comma = regexp(indices,',');
comma = [1 comma length(indices)];
indicesVal = zeros(1,length(comma) - 1);
for tmpIndex = 1:length(comma)-1
    tmpString = indices(comma(tmpIndex)+1:comma(tmpIndex+1)-1);
    indicesVal(tmpIndex) = evalin('base',tmpString);
end

thisFPIstruct = struct();
for tmpIndex=1:length(startStrings)
    startOfFirst = strfind(str,startStrings{tmpIndex});
    endOfFirst = startOfFirst + length(startStrings{tmpIndex});
    startOfNext = strfind(str,endStrings{tmpIndex});
    switching_condition = str(endOfFirst:startOfNext-1);
    
    % Create the entire switching formula
    % Note that the last input is just "default case"
    % We don't use it
    tmpFormula = '';
    for iInp = 2:length(inputNames)-1
        [str2, ~, ~, ~, ~, FPIstruct2] = obj.getSubStructInfo(inputNames{iInp});
        str2 = obj.replaceFPIStrings(str2);
        tmpFormula = [tmpFormula '((' switching_condition ' == ' num2str(indicesVal(iInp-1)) ') and ' str2 ') or '];
        
        for kInp2=1:length(FPIstruct2)
            if isempty(FPIstruct(tmpIndex).prereqSignals)
                thisFPIstruct(end+1).prereqSignals = {[inputNames{1} ' == ' num2str(indicesVal(iInp-1))],FPIstruct2(kInp2).prereqSignals{:}}; %#ok<*AGROW>
            else
                thisFPIstruct(end+1).prereqSignals = {FPIstruct(tmpIndex).prereqSignals{:}, [FPIstruct(tmpIndex).formula ' == ' inputNames{iInp}],FPIstruct2(kInp2).prereqSignals{:}};
            end
            thisFPIstruct(end).prereqFormula = [FPIstruct(tmpIndex).formula '==' num2str(indicesVal(iInp-1))];
            thisFPIstruct(end).formula = FPIstruct2(kInp2).formula;
        end
    end
    tmpFormula = tmpFormula(1:end-4);
end
thisFPIstruct(1) = [];

startDelayList = zeros(length(inputNames),1);
endDelayList = zeros(length(inputNames), 1);
depthList = zeros(length(inputNames),1);
modalDepthList = zeros(length(inputNames),1);
for nDelay = 1:length(inputNames)
    [~, startDelayN, endDelayN, depthN, modalDepthN, ~] = obj.getSubStructInfo(inputNames{nDelay});
    startDelayList(nDelay) = startDelayN;
    endDelayList(nDelay) = endDelayN;
    depthList(nDelay) = depthN;
    modalDepthList(nDelay) = modalDepthN;
end

updateStruct = struct();
updateStruct.str = tmpFormula;
updateStruct.startDelay = max(startDelayList);
updateStruct.endDelay = max(endDelayList);
updateStruct.depth = max(depthList) + 2;
updateStruct.modalDepth = max(modalDepthList);
updateStruct.FPIstruct = thisFPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

