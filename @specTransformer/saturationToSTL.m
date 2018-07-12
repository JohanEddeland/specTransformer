function saturationToSTL(obj, component)
%SATURATIONTOSTL   This creates an STL formula for a SUBSYSTEM called
%Saturation! 
%

inputNames = obj.getInputNames(component);
[str1, ~, ~, ~, ~] = obj.getSubStructInfo(inputNames{1});
[str2, startDelay2, endDelay2, depth2, modalDepth2, FPIstruct2] = obj.getSubStructInfo(inputNames{2});
[str3, ~, ~, ~, ~] = obj.getSubStructInfo(inputNames{3});

[startStrings1, endStrings1]=obj.getFPIStrings(str1);
startOfFirst1 = strfind(str1,startStrings1{1});
endOfFirst1 = startOfFirst1 + length(startStrings1{1});
startOfNext1 = strfind(str1,endStrings1{1});

[startStrings3, endStrings3]=obj.getFPIStrings(str3);
startOfFirst3 = strfind(str3,startStrings3{1});
endOfFirst3 = startOfFirst3 + length(startStrings3{1});
startOfNext3 = strfind(str3,endStrings3{1});

[startStrings, endStrings]=obj.getFPIStrings(str2);

for tmpIndex=1:length(startStrings)
    startOfFirst = strfind(str2,startStrings{tmpIndex});
    endOfFirst = startOfFirst + length(startStrings{tmpIndex});
    startOfNext = strfind(str2,endStrings{tmpIndex});
    FPIstruct2(tmpIndex).formula = ['min(' str1(endOfFirst1:startOfNext1-1) ', max(' str3(endOfFirst3:startOfNext3-1) ', ' str2(endOfFirst:startOfNext-1) '))'];
    str2 = [str2(1:endOfFirst-1) 'min(' str1(endOfFirst1:startOfNext1-1) ', max(' str3(endOfFirst3:startOfNext3-1) ', ' str2(endOfFirst:startOfNext-1) '))' str2(startOfNext:end)];
end

updateStruct = struct();
updateStruct.str = str2;
updateStruct.startDelay = startDelay2;
updateStruct.endDelay = endDelay2;
updateStruct.depth = depth2;
updateStruct.modalDepth = modalDepth2;
updateStruct.FPIstruct = FPIstruct2;
updateStruct.type = 'signal_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

