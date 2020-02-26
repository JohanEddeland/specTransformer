function minMaxToSTL(obj, component)
%FUNCTION   Description goes here.
%

func = get(component,'Function');

componentStrings = {[func '('], ', ', ')'};

inputNames = obj.getInputNames(component);

if obj.containsMuxSignals(component)
    error('minMax is not implemented for muxed signals');
elseif length(inputNames) == 1
    % There is only 1 input, and that input contains no muxed signals
    % The formula is just "func(input1)"
    componentStrings = {[func '('], ')'};
    obj.genericOperatorToSTL(component, componentStrings, 'signal_exp');
else
    obj.genericOperatorToSTL(component, componentStrings, 'signal_exp');
end

end

