function verdict = containsMuxSignals(obj, component)
% Determines if the current component has any muxed signals as input
inputNames = obj.getInputNames(component);
[~, ~, ~, ~, FPIstruct] = obj.getSubStructInfo(inputNames{1});

% We should perform special operations if two conditions are fulfilled:
% 1. There is only 1 input signal (muxed signal)
% 2. The input signal contains the string "muxSignals"
verdict = 0;
if length(inputNames) > 1
    return
end

% There is only 1 input signal - check if it contains muxed signals
containsMuxSignals = 0;
for k = 1:numel(FPIstruct)
    if ~isempty(strfind(FPIstruct(k).prereqFormula, 'muxSignals')) %#ok<*STREMP>
        verdict = 1;
        return
    end
    
    if ~isempty(strfind(FPIstruct(k).formula, 'muxSignals')) %#ok<*STREMP>
        verdict = 1;
        return
    end
end
end

