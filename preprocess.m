function [preprocessed_data preprocess_params] = preprocess(original_data, parameters, recreate_parameters)
    if length(parameters) == 0
        HSV = 1;
        normalize = 1;
        dimensions = 1000;
        whiten = 1;
        hog = 0;
    else
        HSV = parameters{1};
        normalize = parameters{2};
        dimensions = parameters{3};
        whiten = parameters{4};
        hog = parameters{5};
    end

    REBUILD = length(recreate_parameters) == 0;
    if length(recreate_parameters) == 4
        population_mean = recreate_parameters{1};
        population_std = recreate_parameters{2};
        population_U = recreate_parameters{3};
        population_whiten = recreate_parameters{4};
    elseif length(recreate_parameters) > 0
        disp 'invalid number of args for population_parameters'; fflush(stdout);
        return;
    else
        population_mean = 1;
        population_std = 1;
        population_U = 1;
        population_whiten = 1;
    end

    if HSV
      for sample_i=1:size(original_data, 1)
        data(sample_i, :) = convert_HSV(original_data(sample_i, :), {});
      end
    elseif hog ~= 0
      for sample_i=1:size(original_data, 1)
        data(sample_i, :) = convert_HOG(original_data(sample_i, :), {hog});
      end
    else
        data = original_data;
    end

    if REBUILD
      population_mean = mean(data);
    end
    data = double(data) - population_mean;

    if normalize
        
        if REBUILD
          population_std = std(data);
        end
        data = data ./ population_std;
    end

    if dimensions > 0
      if REBUILD
          disp 'computing covar mat'; fflush(stdout);
          covar = cov(data);
          [U, S, ~] = svd(covar);

          disp 'PCA analysis'; fflush(stdout);
          dimensions = min(dimensions,size(U,2));
          population_U = U(:,1:dimensions);
      end
      data = data * population_U;
    end

    if whiten
        if REBUILD && dimensions > 0
          S = diag(S)';
          population_whiten = sqrt(S(1:dimensions) + 1.0e-50);
        end
        data = data ./ population_whiten;
    end

    preprocessed_data = data;
    preprocess_params = {population_mean population_std population_U population_whiten};
end
