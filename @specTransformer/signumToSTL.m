function signumToSTL(obj, component)
%FUNCTION   Description goes here.
%

componentStrings = {'sign(', ')'};
obj.genericOperatorToSTL(component, componentStrings, 'signal_exp')

end

