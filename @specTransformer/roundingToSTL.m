function roundingToSTL(obj, component)
%FUNCTION   Description goes here.
%

oper = get(component, 'Operator');
componentStrings = {[oper '('], ')'};
obj.genericOperatorToSTL(component, componentStrings, 'signal_exp')

end

