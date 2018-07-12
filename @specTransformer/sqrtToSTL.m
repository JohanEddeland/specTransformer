function sqrtToSTL(obj, component)
%FUNCTION   Description goes here.
%

componentStrings = {'sqrt(', ')'};
obj.genericOperatorToSTL(component, componentStrings, 'signal_exp')

end

