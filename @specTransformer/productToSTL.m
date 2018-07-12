function productToSTL(obj, component)
%FUNCTION   Description goes here.
%

operatorList = get(component,'Inputs');
if length(operatorList)==1
    operatorList = '**';
end
operator = operatorList(2);
inputNames = obj.getInputNames(component);

if length(inputNames)==1
    % Only one input
    % We use MATLAB command 'prod' to take the product of all elements in
    % the (supposedly) vector input
    componentStrings = {'prod(', ')'};
    obj.genericOperatorToSTL(component, componentStrings, 'signal_exp');
else
    % Multiple inputs
    % Define formula based on '*' operator
    componentStrings = {'(', operator, ')'};
    obj.genericOperatorToSTL(component, componentStrings, 'signal_exp')
end


end

