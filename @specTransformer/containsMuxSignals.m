function verdict = containsMuxSignals(obj, component)
% Determines if the current component has any muxed signals as input
inputNames = obj.getInputNames(component);
[str, ~, ~, ~, ~, ~] = obj.getSubStructInfo(inputNames{1});

% We should perform special operations if two conditions are fulfilled:
% 1. There is only 1 input signal (muxed signal)
% 2. The input signal contains the string "muxSignals"
verdict = (length(inputNames)==1) && (~isempty(strfind(str, 'muxSignals')));
end

