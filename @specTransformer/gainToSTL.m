function gainToSTL(obj, component)
%FUNCTION   Description goes here.
%

gain = get(component,'Gain');

inputNames = obj.getInputNames(component);
inputType = obj.getType(inputNames{1});

if strcmp(inputType,'phi_exp') && strcmp(gain, '-1')
    % The input is logical and we should negate it
    componentStrings = {'not(', ')'};
    obj.genericOperatorToSTL(component, componentStrings, 'phi_exp');
else
    % Assert that the input is a signal expression
    assert(strcmp(inputType, 'signal_exp'));
    componentStrings = {'(', ['*' gain ')']};
    obj.genericOperatorToSTL(component, componentStrings, 'signal_exp');
end



end

