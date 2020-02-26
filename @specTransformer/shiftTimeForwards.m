function newFormula = shiftTimeForwards(formula, timeshift)

%% Replace [t-X*dt] with [t-(X-timeshift)*dt]
[startIndex,endIndex] = regexp(formula,'\-\d**');
% Find all the numbers (timeshifts) to replace
numbersToReplace = zeros(1, length(startIndex));
for iTmp = 1:length(startIndex)
    X = formula(startIndex(iTmp)+1:endIndex(iTmp)-1);
    X = str2double(X);
    numbersToReplace(iTmp) = X;
end
numbersToReplace = unique(numbersToReplace);
for iTmp = length(numbersToReplace):-1:1
    strToReplace = ['[t-' num2str(numbersToReplace(iTmp)) '*dt]'];
    newStr = ['[t-' num2str(numbersToReplace(iTmp) - str2double(timeshift)) '*dt]'];
    formula = strrep(formula,strToReplace,newStr);
end

%% Replace [t] with [t+timeshift*dt]
newFormula = regexprep(formula,'\[t\]',['[t+' timeshift '*dt]']);

end