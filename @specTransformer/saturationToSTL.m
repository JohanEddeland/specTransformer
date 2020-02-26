function saturationToSTL(obj, component)
%SATURATIONTOSTL   This creates an STL formula for a SUBSYSTEM called
%Saturation! 
%

inputNames = obj.getInputNames(component);
[~, ~, ~, ~, FPIstruct1] = obj.getSubStructInfo(inputNames{1});
[str2, startDelay2, endDelay2, depth2, modalDepth2, FPIstruct2] = obj.getSubStructInfo(inputNames{2});
[~, ~, ~, ~, FPIstruct3] = obj.getSubStructInfo(inputNames{3});

maxString = FPIstruct1(1).formula;
assert(length(FPIstruct1) == 1, 'We expect a constant value as max value for saturation');

minString = FPIstruct3(1).formula;
assert(length(FPIstruct2) == 1, 'We expect a constant value as min value for saturation');

for tmpIndex=1:length(FPIstruct2)
    FPIstruct2(tmpIndex).formula = ['min(' maxString ', max(' minString ', ' FPIstruct2(tmpIndex).formula '))'];
end

updateStruct = struct();
updateStruct.startDelay = startDelay2;
updateStruct.endDelay = endDelay2;
updateStruct.depth = depth2;
updateStruct.modalDepth = modalDepth2;
updateStruct.FPIstruct = FPIstruct2;
updateStruct.type = 'signal_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

