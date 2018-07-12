function component = sumToSTL(obj, component)
%FUNCTION   Description goes here.
%

operatorList = get(component,'Inputs');
inputNames = obj.getInputNames(component);

% Small fix: For some sum-blocks, the list of operators will be e.g. '|++'
% This is for 2 inputs. We should remove the occurrence of '|'
operatorList = strrep(operatorList, '|', '');

if length(operatorList)==1
    operatorList = '++';
end
operator = operatorList(2);

% First, check if there are any inputs that are phi_exp
thereArePhiExp = 0;
inputNames = obj.getInputNames(component);
for k = 1:length(inputNames)
    thisType = obj.getType(inputNames{k});
    if strcmp(thisType, 'phi_exp')
        thereArePhiExp = 1;
    end
end

componentStrings = {'(', operator, ')'};
if obj.containsMuxSignals(component)
    if thereArePhiExp
        disp('WARNING: Trying to sum up STL-formulas with muxed signals. Logging output of sum-block instead');
        obj.logOneBlock(component);
    else
        % Signal expression as input - business as usual (summing up
        % signals is fine)
        sumWithMuxSignals(obj, component, componentStrings);
    end
    
elseif length(inputNames) == 1
    if thereArePhiExp
        sumWithPhiExp(obj, component, inputNames, {'sum(', ')'}, 'signal_exp');
    else
        % There is only 1 input, and that input contains no muxed signals
        % The formula is just "sum(input1)"
        obj.genericOperatorToSTL(component, {'sum(', ')'}, 'signal_exp');
    end
else
    if thereArePhiExp
        error('So far undefined what to do when there are phi_exp to sum up');
    else
        % No muxed signals - business as usual
        obj.genericOperatorToSTL(component, componentStrings, 'signal_exp', operatorList)
    end
end

end


function sumWithMuxSignals(obj, component, componentStrings, oldInputNames)

% This function is a modified version of genericNInputsToSTL, found in the
% file genericOperatorToSTL.m
% The modification consists of replacing "muxSignals#" with the actual
% values of each signal that has been muxed

%inputNames = obj.getInputNames(component);
if nargin == 3
    % No oldInputNames specified
    oldInputNames = obj.getInputNames(component);
end
[oldStr1, ~, ~, ~, ~, oldFPIstruct1] = obj.getSubStructInfo(oldInputNames{1});

% k loops over all possible muxSignals name (muxSignals1, muxSignals2 etc)
inputValues = {};
inputFPIStructs = {};
inputStartDelays = [];
inputEndDelays = [];
inputDepths = [];
inputModalDepths = [];
for k = 1:obj.muxCounter-1
    muxInputNames = obj.muxSignals(k).inputNames;
    
    if isempty(strfind(oldStr1, ['muxSignals' num2str(k)]))
        % The input does not contain any occurences of this muxSignals
        % Nothing needs to be done for this k
    else
        % kk loops over all muxed signals in the current muxSignals
        for kk = 1:length(muxInputNames)
            % For each signal, we want to replace muxSignals with the actual
            % signal value!
            [muxStr, muxStartDelay, muxEndDelay, muxDepth, muxModalDepth, muxFPIstruct] = obj.getSubStructInfo(muxInputNames{kk});
            inputStartDelays(end+1) = muxStartDelay; %#ok<*AGROW>
            inputEndDelays(end+1) = muxEndDelay;
            inputDepths(end+1) = muxDepth;
            inputModalDepths(end+1) = muxModalDepth;
            [startStrings, endStrings] = obj.getFPIStrings(muxStr);
            
            %Currently only implemented for ONE start string and end string
            assert(length(startStrings) == 1);
            assert(length(endStrings) == 1);
            
            startOfFirst = strfind(muxStr, startStrings{1});
            endOfFirst = startOfFirst + length(startStrings{1});
            startOfNext = strfind(muxStr,endStrings{1});
            
            muxStrWithoutFPI = muxStr(endOfFirst:startOfNext-1);
            muxStr = replaceOldStringsToMux(obj, oldStr1, k, muxStrWithoutFPI);
            inputValues{end+1} = muxStr; 
            
            % For each signal, we want to replace muxSignals with the actual
            % signal value!
            [startStrings, endStrings] = obj.getFPIStrings(muxStr);
            
            %Currently only implemented for ONE start string and end string
            assert(length(startStrings) == 1);
            assert(length(endStrings) == 1);
            
            startOfFirst = strfind(muxStr, startStrings{1});
            endOfFirst = startOfFirst + length(startStrings{1});
            startOfNext = strfind(muxStr,endStrings{1});
            
            muxFPIstruct.formula = muxStr(endOfFirst:startOfNext-1);
            
            inputFPIStructs{end+1} = muxFPIstruct;
        end
    end
end

% componentStrings here: {'(', '+', ')'}
compString1 = componentStrings{1};
compString2 = componentStrings{2};
compString3 = componentStrings{3};

numOfPairs = length(inputValues)-1;

str1 = inputValues{1};
FPIstruct1 = inputFPIStructs{1};
str2 = inputValues{2};
FPIstruct2 = inputFPIStructs{2};

FPIstruct = struct();
for nPairs = 1:numOfPairs
    [startStrings1, endStrings1] = obj.getFPIStrings(str1);
    [startStrings2, endStrings2] = obj.getFPIStrings(str2);
    
    oldstr2 = str2;
    for tmpIndex=1:length(startStrings1)
        startOfFirst1 = strfind(str1,startStrings1{tmpIndex});
        endOfFirst1 = startOfFirst1 + length(startStrings1{tmpIndex});
        startOfNext1 = strfind(str1,endStrings1{tmpIndex});
        endOfNext1 = startOfNext1 + length(endStrings1{tmpIndex});
        term1 = str1(endOfFirst1:startOfNext1-1);
        
        str2 = oldstr2;
        for tmpIndex2=1:length(startStrings2)
            startOfFirst2 = strfind(str2,startStrings2{tmpIndex2});
            endOfFirst2 = startOfFirst2 + length(startStrings2{tmpIndex2});
            startOfNext2 = strfind(str2,endStrings2{tmpIndex2});
            term2 = str2(endOfFirst2:startOfNext2-1);
            
            % Update prereqSignals
            if isempty(FPIstruct1(tmpIndex).prereqSignals) && ...
                    isempty(FPIstruct2(tmpIndex2).prereqSignals) && ...
                    length(FPIstruct) > 1
                % Empty prerequisites! We do not
                % need to add another instance to
                % FPIstruct
                FPIstruct(end).prereqSignals = {FPIstruct1(tmpIndex).prereqSignals{:}, FPIstruct2(tmpIndex2).prereqSignals{:}};
            else
                FPIstruct(end+1).prereqSignals = {FPIstruct1(tmpIndex).prereqSignals{:}, FPIstruct2(tmpIndex2).prereqSignals{:}};  %#ok<*CCAT>
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
            
            str2 = [str2(1:endOfFirst2-1) compString1 term1 ' ' compString2 ' ' term2 compString3 str2(startOfNext2:end)];
            FPIstruct(end).formula = [compString1 FPIstruct1(tmpIndex).formula ' ' compString2 ' ' FPIstruct2(tmpIndex2).formula compString3];
        end
        str2 = obj.replaceFPIStrings(str2);
        str1 = [str1(1:startOfFirst1-1) str2 str1(endOfNext1:end)];
    end
    
    try
        str2 = inputValues{2};
        FPIstruct2 = inputFPIStructs{2};
        FPIstruct1 = FPIstruct;
        FPIstruct1(1) = [];
    catch
    end
end
FPIstruct(1) = [];

updateStruct = struct();
updateStruct.str = str1;
updateStruct.startDelay = max(inputStartDelays);
updateStruct.endDelay = max(inputEndDelays);
updateStruct.depth = max(inputDepths);
updateStruct.modalDepth = max(inputModalDepths);
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'signal_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);


end

function newStr = replaceOldStringsToMux(obj, oldStr, k, muxStr)
% oldStr is the string containing muxSignals1[t], muxSignals2[t] etc ...
% k is a number of the current number to exchange (1 in muxSignals 1 for
% example).
% muxStrWithoutFPI is what muxSignals1[t] should be replaced for

stringsToReplaceIndices = strfind(oldStr, ['muxSignals' num2str(k)]);
stringsToReplace = cell(1, length(stringsToReplaceIndices));
leftBrackets = strfind(oldStr, '[');
rightBrackets = strfind(oldStr, ']');
timesToShift = struct();
for strCounter = 1:length(stringsToReplaceIndices)
    % We need to find "[t]", "[t-1]" or whatever in the string to replace
    stringsToReplaceIndex = stringsToReplaceIndices(strCounter);
    leftBracketIndex = leftBrackets(find(leftBrackets > stringsToReplaceIndex, 1));
    rightBracketIndex = rightBrackets(find(rightBrackets > stringsToReplaceIndex, 1));
    
    stringsToReplace{strCounter} = oldStr(stringsToReplaceIndex:rightBracketIndex);
    
    % Find the number that is shifted
    shiftedPartOfOldStr = oldStr(leftBracketIndex:rightBracketIndex);
    [shiftStart, shiftEnd] = regexp(shiftedPartOfOldStr, '\d');
    if isempty(shiftStart)
        timesToShift(strCounter).time = 0;
        timesToShift(strCounter).type = 'none';
    else
        timesToShift(strCounter).time = shiftedPartOfOldStr(shiftStart:shiftEnd);
        if strfind(shiftedPartOfOldStr, '+')
            timesToShift(strCounter).type = 'forwards';
        elseif strfind(shiftedPartOfOldStr, '-')
            timesToShift(strCounter).type = 'backwards';
        else
            error('Is the time shift forwards or backwards?');
        end
            
    end
end

% Only keep unique entries in stringsToReplace and timesToShift
[stringsToReplace, idx] = unique(stringsToReplace);
timesToShift = timesToShift(idx);

newStr = oldStr;
for strCounter = 1:length(stringsToReplace)
    shiftTime = timesToShift(strCounter).time;
    shiftType = timesToShift(strCounter).type;
    if shiftTime == 0
        % Need no time shift of muxStr
        newStr = strrep(newStr, stringsToReplace{strCounter}, muxStr);
    elseif strcmp(shiftType, 'forwards')
        newStr = strrep(newStr, stringsToReplace{strCounter}, ...
            obj.shiftTimeForwards(muxStr, shiftTime));
    elseif strcmp(shiftType, 'backwards')
        newStr = strrep(newStr, stringsToReplace{strCounter}, ...
            obj.shiftTimeBackwards(muxStr, shiftTime));
    else
        error('Unexpected behaviour');
    end
end

end

function sumWithPhiExp(obj, component, inputNames, componentStrings, type)
% This function is a modified version of genericOneInputToSTL, found in the
% file genericOperatorToSTL.m
% The modification consists of replacing "and" and "or" with "&&" and 
% "||" in the strings that we apply "sum()" to.

% We should have exactly two componentStrings to use
assert(length(componentStrings) == 2);

compString1 = componentStrings{1};
compString2 = componentStrings{2};

[str, startDelay, endDelay, depth, modalDepth, FPIstruct] = obj.getSubStructInfo(inputNames{1});

str = obj.replaceFPIStrings(str);
[startStrings, endStrings] = obj.getFPIStrings(str);

for tmpIndex=1:length(startStrings)
    startOfFirst = strfind(str,startStrings{tmpIndex});
    endOfFirst = startOfFirst + length(startStrings{tmpIndex});
    startOfNext = strfind(str,endStrings{tmpIndex});
    
    % Replace ' and ' with ' && ' and repalce ' or ' with ' || '
    % First replace in the FPI formula
    replacedFPI = strrep(FPIstruct(tmpIndex).formula, ' and ', ' && ');
    replacedFPI = strrep(replacedFPI, ' or ', ' || ');
    % Then replace in the part of str that we surround with "sum()"
    replacedStr = strrep(str(endOfFirst:startOfNext-1), ' and ', ' && ');
    replacedStr = strrep(replacedStr, ' or ', ' || ');
    
    FPIstruct(tmpIndex).formula = [compString1 replacedFPI compString2];
    str = [str(1:endOfFirst-1) compString1 replacedStr compString2 str(startOfNext:end)];
end

% str is the formula
% delay is the same as for input
% depth is 1 more than input
% modal depth is the same as for input
updateStruct = struct();
updateStruct.str = str;
updateStruct.startDelay = startDelay;
updateStruct.endDelay = endDelay;
updateStruct.depth = depth + 1;
updateStruct.modalDepth = modalDepth;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = type;
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end
