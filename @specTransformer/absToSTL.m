function absToSTL(obj, component)
%FUNCTION   Description goes here.
%

componentStrings = {'abs(', ')'};
obj.genericOperatorToSTL(component, componentStrings, 'signal_exp')

end

