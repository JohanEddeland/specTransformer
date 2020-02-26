function sampleTimeMathToSTL(obj, component)
%FUNCTION   Description goes here.
%

inputNames = obj.getInputNames(component);
[startDelay, endDelay, depth, modalDepth, FPIstruct] = obj.getSubStructInfo(inputNames{1});

dt = get(component,'CompiledSampleTime');
dt = dt(1);

for k=1:length(FPIstruct)
    FPIstruct(k).formula = [FPIstruct(k).formula '/' num2str(dt)];
end

updateStruct = struct();
updateStruct.startDelay = startDelay;
updateStruct.endDelay = endDelay;
updateStruct.depth = depth + 1;
updateStruct.modalDepth = modalDepth;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'signal_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct);

end

