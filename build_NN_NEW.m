function model = build_NN_NEW(data, labels, parameters)
  if length(parameters) == 0
    classes = 10;
    hidden_layers = []; % col vector [500 500]
    learning_rate = .05;
    acc_thresh = .95;
    epoch_num = 20;
    batch_size = 100;
    eval_size = 100;
  else
    classes = parameters{1};
    hidden_layers = parameters{2};
    learning_rate = parameters{3};
    if parameters{4} >= 1
      acc_thresh = 2;
      epoch_num = parameters{4};
    else
      acc_thresh = parameters{4};
      epoch_num = 1000;
    end
    batch_size = parameters{5};
    if parameters{6} > 0
      eval_size = parameters{6};
    else
      eval_size = size(data, 1);
    end
  end

  %  model = build_NN_NEW(d, l, {10 [] .05 .8 10 100});
  lamb = .0001; % regularization parameter. should eventually go to parameters
  
  means = mean(double(data));

  original_data = double(data);  
  data = (double(data)-means)/127.0; % normalize data
  original_labels = labels;
  labels = labels + 1; % octave likes things to be 1-indexed
  
  layers = horzcat([size(data, 2)], hidden_layers, [classes]);
  L = size(layers, 2); % number of layers (besides input)
  N = size(data, 1);

  weights = cell(L, 1);
  batch_weights = cell(L, 1);
  biases = cell(L, 1);
  batch_biases = cell(L, 1);
  activation = cell(L, 1);
  z = cell(L, 1);
  deltas = cell(L, 1);
  for layer_i=1:L
    % initialize a random weight for each input and 0 for each bias
    if layer_i > 1
      weights{layer_i} = normrnd(0, 1, [layers(layer_i-1), layers(layer_i)])*sqrt(2/layers(layer_i-1));
      biases{layer_i} = zeros(1, layers(layer_i));
    end
    z{layer_i} = zeros(layers(layer_i), 1);
    activation{layer_i} = zeros(layers(layer_i), 1);
    delta{layer_i} = zeros(layers(layer_i), 1);
  end

  %old_weights = weights;
  old_acc = 0;
  old_e = 0;
  
  %c = onCleanup(@()clean(weights, biases));
  
  epoch_count = 0;
  for epoch_i=1:epoch_num
    "\n"
    epoch_i
  
    % take a random sample of data
    idx = randperm(size(data, 1));
    for batch_start=1:batch_size:size(data, 1)-batch_size
      batch_data = data(idx(batch_start:batch_start+batch_size), :);
      batch_labels = labels(idx(batch_start:batch_start+batch_size), :);
      batch_answer = make_ans(classes, batch_labels);
    
      %features = batch_data(sample_i, :);
      %answer = make_ans(classes, batch_labels(sample_i));
      
      % calculate output for each node for each layer
      activation{1} = batch_data;
      for layer_i=2:L
        z{layer_i} = activation{layer_i-1}*weights{layer_i} + biases{layer_i}; %'
        activation{layer_i} = relu(z{layer_i});
      end
      output = sftprobs(z{L});
      
      % calculate delta for each node for each layer
      deltas = cell(L, 1);
      deltas{L} = (output-batch_answer)/batch_size;
      for layer_i=L-1:-1:2
        deltas{layer_i} = deltas{layer_i+1}*weights{layer_i+1}' .* reludiff(z{layer_i}); %'
      end

      % update batch weights and biases
      for layer_i=2:L
        batch_weights{layer_i} = lamb*weights{layer_i} + (activation{layer_i-1}'*deltas{layer_i}); %'
        batch_biases{layer_i} = sum(deltas{layer_i});
      end
      
      % update weights and biases
      for layer_i=2:L
        weights{layer_i} = weights{layer_i} - (learning_rate/batch_size)*batch_weights{layer_i};
        biases{layer_i} = biases{layer_i} - (learning_rate/batch_size)*batch_biases{layer_i};
      end
      % diff = weights{2} - old_weights{2}
    end
    
    % evaluate performance
    idx = 1:size(data, 1);%randperm(size(data, 1));
    eval_data = original_data(idx(1:eval_size), :);
    eval_labels = original_labels(idx(1:eval_size), 1);
    good = zeros(1, eval_size);
    e = 0;
    for sample_i=1:eval_size
      %out = test_NN({weights biases}, eval_data(sample_i, :))
      [guess output] = test_NN({weights biases {means}}, eval_data(sample_i, :));
      % if sample_i == 1 output end
      answ = eval_labels(sample_i);
      e = e + softmax_loss(classes, output, answ+1);
      if guess == answ
        good(sample_i) = 1;
        % "right"
        % sample_j
      end
    end
    %good
    
    e = e/eval_size + reg_loss(weights, lamb);
    acc = sum(good)/eval_size
    e

    acc_diff = acc - old_acc
    old_acc = acc;
    e_diff = e - old_e
    old_e = e;
    
    if acc > acc_thresh
      break
    end

    %sum(sum(abs(weights{2}-old_weights{2})))
    %sum(sum(abs(weights{3}-old_weights{3})))
    %sum(sum(abs(weights{4}-old_weights{4})))
    %old_weights = weights;

    fflush(stdout);
  end
  
  model = {weights biases {means}};

end

nl = sigmf

function ans = sigmf(x)
  ans = 1.0 ./ (1.0 + exp(-x));
end

function ans = relu(x)
  ans = (x > 0).*x;
end

function ans = reludiff(x)
  ans = double(x > 0);
end

function err = entropy_loss(c, output, answ)
  t = make_ans(c, answ);
  err = sum(t.*log(output) + (1-t).*log(1-output));
end

function err = hinge_loss(c, output, answ)
  diff = (output-output(answ+1))+1;
  diff = diff .* (diff > 0);
  err = sum(diff) - 1;
end

function err = softmax_loss(c, output, answ)
  probs = sftprobs(output);
  err = -log(probs(answ));
end

function err = reg_loss(w, lamb)
  err = 0;
  for i=1:size(w)
    err = err + .5*lamb*sum(sum(w{i}.*w{i}));
  end
end

function err = reg_gradient(w, lamb)
  err = lamb*w;
end

function ans = softmax_gradient(c, output, answ)
  probs = sftprobs(output);
  ans = probs - (make_ans(c, answ))';
end

function probs = sftprobs(vec)
  expd = exp(vec);
  probs = expd./sum(expd, 2);
end

function clean(weights, biases)
  model={weights,biases};
  save('model.mat', 'model')
end

function t = make_ans(c, labels)
  t = zeros(size(labels,1), c);
  for i=1:size(labels,1)
    t(i, labels(i)) = 1;
  end
end