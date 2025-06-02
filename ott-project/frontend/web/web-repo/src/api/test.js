import axios from 'axios'

export const testAPI = async () => {
  const res = await axios.get('https://jsonplaceholder.typicode.com/posts/1')
  console.log(res.data)
}

