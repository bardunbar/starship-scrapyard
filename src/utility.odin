package main


array_swap_back :: proc (array: ^[]$T, index_to_remove, index_to_swap: int) {
    if (index_to_remove <= index_to_swap && index_to_swap < len(array)) {
        array[index_to_remove] = array[index_to_swap]
    }
}