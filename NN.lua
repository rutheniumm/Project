-- Define the neural network architecture
local NeuralNetwork = {
  inputLayer = 4,   -- Number of input neurons
  hiddenLayer = 8,  -- Number of neurons in the hidden layer
  outputLayer = 2   -- Number of output neurons
}

-- Initialize the neural network
function NeuralNetwork:init()
  self.weightsInputHidden = {}
  self.weightsHiddenOutput = {}
  
  -- Initialize weights randomly
  for i = 1, self.hiddenLayer do
    self.weightsInputHidden[i] = {}
    for j = 1, self.inputLayer do
      self.weightsInputHidden[i][j] = math.random()
    end
  end
  
  for i = 1, self.outputLayer do
    self.weightsHiddenOutput[i] = {}
    for j = 1, self.hiddenLayer do
      self.weightsHiddenOutput[i][j] = math.random()
    end
  end
end

-- Define the sigmoid activation function
local function sigmoid(x)
  return 1 / (1 + math.exp(-x))
end

-- Forward propagation through the neural network
function NeuralNetwork:forward(input)
  local hiddenLayerOutput = {}
  local output = {}
  
  -- Calculate output of hidden layer
  for i = 1, self.hiddenLayer do
    local sum = 0
    for j = 1, self.inputLayer do
      sum = sum + input[j] * self.weightsInputHidden[i][j]
    end
    hiddenLayerOutput[i] = sigmoid(sum)
  end
  
  -- Calculate final output
  for i = 1, self.outputLayer do
    local sum = 0
    for j = 1, self.hiddenLayer do
      sum = sum + hiddenLayerOutput[j] * self.weightsHiddenOutput[i][j]
    end
    output[i] = sigmoid(sum)
  end
  
  return output
end

-- Training function (backpropagation algorithm)
function NeuralNetwork:train(inputs, targets, learningRate)
  -- Forward pass
  local hiddenLayerOutput = {}
  local output = {}
  for i = 1, self.hiddenLayer do
    local sum = 0
    for j = 1, self.inputLayer do
      sum = sum + inputs[j] * self.weightsInputHidden[i][j]
    end
    hiddenLayerOutput[i] = sigmoid(sum)
  end
  for i = 1, self.outputLayer do
    local sum = 0
    for j = 1, self.hiddenLayer do
      sum = sum + hiddenLayerOutput[j] * self.weightsHiddenOutput[i][j]
    end
    output[i] = sigmoid(sum)
  end
  
  -- Backward pass
  local outputErrors = {}
  local hiddenErrors = {}
  
  for i = 1, self.outputLayer do
    outputErrors[i] = targets[i] - output[i]
  end
  
  for i = 1, self.hiddenLayer do
    local error = 0
    for j = 1, self.outputLayer do
      error = error + outputErrors[j] * self.weightsHiddenOutput[j][i]
    end
    hiddenErrors[i] = error
  end
  
  -- Update weights
  for i = 1, self.outputLayer do
    for j = 1, self.hiddenLayer do
      self.weightsHiddenOutput[i][j] = self.weightsHiddenOutput[i][j] + learningRate * outputErrors[i] * hiddenLayerOutput[j] * (1 - hiddenLayerOutput[j])
    end
  end
  
  for i = 1, self.hiddenLayer do
    for j = 1, self.inputLayer do
      self.weightsInputHidden[i][j] = self.weightsInputHidden[i][j] + learningRate * hiddenErrors[i] * inputs[j] * (1 - inputs[j])
    end
  end
end

return NeuralNetwork
