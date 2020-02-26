function logicToSTL(obj, component)
%FUNCTION   Description goes here.
%

oper = get(component,'Operator');
inputNames = obj.getInputNames(component);

if strcmp(oper,'OR')
    % OR block
    if length(inputNames) == 1
        % Only one input (vector input)
        % We use 'any()', which is a generalization or 'or()' for vectors
        % Note that this will not give any specific robustness calculations
        % ... maybe we want to create separate or's for each vector
        % element?
        componentStrings = {'any(', ')'};
    else
        % Several inputs 
        % Use 'or', so that Breach can calculate robustness in the correct
        % way
        componentStrings = {'(', ' or ', ')'};
    end
    
elseif strcmp(oper,'NOT')
    componentStrings = {'not(', ')'};
    
elseif strcmp(oper,'AND')
    if length(inputNames) == 1
        % Only one input (vector input)
        % We use 'all()', generalization of 'and()' for vectors
        componentStrings = {'all(', ')'};
    else
        % Several inputs
        % Use 'and' which is interpreted by Breach as usual
        componentStrings = {'(', ' and ', ')'};
    end
    
elseif strcmp(oper, 'NOR')
    componentStrings = {'not(', ' or ', ')'};
    
else
    error(['Define what to do for this logical operator: ' oper]);
end

obj.genericOperatorToSTL(component, componentStrings, 'phi_exp');

end

