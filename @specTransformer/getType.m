function subType = getType(obj, inputName)
% Returns the type of a subformula
% %%% Inputs
% obj is a testronSTL object
% inputName is a string, for example 'sub1' or 'sub453'
% %%% Output
% subType is the type of the sub-formula
[startIndex, endIndex] = regexp(inputName, '\d*');
digitAsString = inputName(startIndex:endIndex);
subIndex = str2double(digitAsString);
subType = obj.subStruct(subIndex).type;
end