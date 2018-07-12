function outportToSTL(obj, component)
%FUNCTION   Description goes here.
%

% We have arrived at our final destination
% Save the final formula in the corresponding STL file
inputName = obj.getInputNames(component);
[str, startDelay, endDelay, ~, ~, FPIstruct] = obj.getSubStructInfo(inputName{1});

if obj.subSystemLevel > 0
    % We're in a subSystem - do nothing!
else
    % In the start of the file, write the string about skipped signals
    fprintf(obj.fileID,obj.skippedString);
    fprintf(obj.fileID,'\n');
    
    % Then, write the parameters and their values
    obj.paramString = obj.paramString(1:end-2);
    fprintf(obj.fileID,obj.paramString);
    fprintf(obj.fileID,'\n\n');
    
    % Write the whole formula string
    if ~isempty(obj.formulaString)
        fprintf(obj.fileID, obj.formulaString);
    end
    
    % Write the SMT subrequirements
    fprintf(obj.fileID,'# =========== SUBREQUIREMENTS ============\n');
    if length(FPIstruct) == 1
        fprintf(obj.fileID, '# No prerequisites!\n');
        fprintf(obj.fileID, ['phi_sub1 := ' FPIstruct(1).formula '\n\n']);
    else
        for kk = 1:length(FPIstruct)
            fprintf(obj.fileID, ['# Prerequisite ' num2str(kk) ' #\n']);
            % Remove identical entries coming from
            % different switches
            FPIstruct(kk).prereqSignals = unique(FPIstruct(kk).prereqSignals);
            try
                prereqSignals = FPIstruct(kk).prereqSignals{1};
            catch
                % prereqSignals is empty
                prereqSignals = '';
            end
            for kpr = 2:length(FPIstruct(kk).prereqSignals)
                prereqSignals = [prereqSignals ', ' FPIstruct(kk).prereqSignals{kpr}]; %#ok<AGROW>
            end
            fprintf(obj.fileID, ['# ' prereqSignals '\n']);
            
            % Fix potential errors in the prerequisite, namely add "==1" where it's
            % missing
            FPIstruct(kk).prereqFormula = fixErrorsInSTLFormula(FPIstruct(kk).prereqFormula);
            fprintf(obj.fileID, ['prereq' num2str(kk) ' := ' FPIstruct(kk).prereqFormula '\n']);
            
            % Fix potential errors in the formula, namely add "==1" where it's
            % missing
            FPIstruct(kk).formula = fixErrorsInSTLFormula(FPIstruct(kk).formula);
            
            fprintf(obj.fileID, ['phi_sub' num2str(kk) ' := ' FPIstruct(kk).formula '\n\n']);
        end
    end
    
    fprintf(obj.fileID,'# =========== FINAL REQUIREMENT ===========\n');
    
    % First, write the version of the requirement where we interpret
    % switches with "=>"
    fprintf(obj.fileID, '# phi_implies is the formula when interpreting switches using "=>"\n');
    
    if length(FPIstruct) == 1
        fprintf(obj.fileID, ['phi_implies := ' FPIstruct(1).formula '\n\n']);
    else
        fprintf(obj.fileID, 'phi_implies := ');
        for kk = 1:length(FPIstruct)-1
            fprintf(obj.fileID, ['(' FPIstruct(kk).prereqFormula ' => ' FPIstruct(kk).formula ') and ']);
        end
        % Write the final prereq and formula
        fprintf(obj.fileID, ['(' FPIstruct(end).prereqFormula ' => ' FPIstruct(end).formula ')\n\n']);
    end
    
    
    % Remove all the FPI indicators
    % Remove all the start strings ({1}, {2} etc)
    str = regexprep(str,'{\d*}','');
    str = regexprep(str,'{/\d*}','');
    
    % Fix errors in the formula
    str = fixErrorsInSTLFormula(str);
    
    % Create "init"-time
    if startDelay == 0
        initTimeString = 't_init';
    else
        initTimeString = ['t_init + ' num2str(startDelay) '*dt'];
    end
    
    % Create end-time
    if endDelay == 0
        endTimeString = 't_final';
    else
        endTimeString = ['t_final - ' num2str(endDelay) '*dt'];
    end
    
    % Print the final requirement
    if strcmp(obj.specType, 'safety')
        fprintf(obj.fileID,['phi := alw_[' initTimeString ',' endTimeString '](' str ')\n']);
    elseif strcmp(obj.specType, 'none')
        fprintf(obj.fileID,['phi := ' str '\n']);
    else
        error('Unknown requirement type (not safety or none)');
    end
    fclose(obj.fileID);
    
    if length(str) > obj.charLimit
        % The STL formula is too long!
        if ~isdir([obj.resultsFolder '/TooLong'])
            mkdir([obj.resultsFolder '/TooLong']);
        end
        
        % Move the file into TooLong directory
        movefile([resultsFolder '/' filename '.stl'],[resultsFolder '/TooLong/' filename '.stl']);
        
        obj.tooLongSTLFormula = 1;
    end
    
end

end

function newPhi = fixErrorsInSTLFormula(phi)
% phi is a string, so newPhi is also a string
STL_cont_flag = 1;

while STL_cont_flag
    try
        formula = STL_Formula('phi', phi);
        newPhi = disp(formula);
        STL_cont_flag = 0;
    catch
        % We must replace 'var_to_replace' with 'var_to_replace==1'
        var_to_replace = evalin('base','var_to_replace;');
        disp(['Replacing ' var_to_replace ' with ' var_to_replace '==1']);
        
        phi = strrep(phi, var_to_replace, [var_to_replace '==1']);
        
    end
end
end


