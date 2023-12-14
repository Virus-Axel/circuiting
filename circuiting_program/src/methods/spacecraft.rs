use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint::ProgramResult,
    msg,
    program_error::ProgramError,
    pubkey::Pubkey,
    system_instruction,
    sysvar::{rent::Rent, Sysvar},
    program::invoke,
};

const OWNER_SIZE: usize = 32;
const HEALTH_SIZE: usize = 2;
const SPEED_SIZE: usize = 1;
const LOCATION_SIZE: usize = 32;
const MAX_BOARD_WIDTH: u8 = 64;
const MAX_BOARD_HEIGHT: u8 = 128;
const DATA_SIZE_PER_UNIT: u8 = 3; // Component type, input 1, component specific data,

fn spacecraft_account_size() -> usize {
    (MAX_BOARD_HEIGHT as usize) * (MAX_BOARD_WIDTH as usize) * (DATA_SIZE_PER_UNIT as usize)
        + LOCATION_SIZE
        + SPEED_SIZE
        + HEALTH_SIZE
        + OWNER_SIZE
}

fn set_health(data: &mut [u8], health :u16){
    data[OWNER_SIZE..(OWNER_SIZE + HEALTH_SIZE)].copy_from_slice(&health.to_le_bytes());
}

fn set_pcb_array_element(data: &mut [u8], x: u8, y: u8, value: u8){
    const ARRAY_OFFSET: usize = OWNER_SIZE + HEALTH_SIZE + SPEED_SIZE + LOCATION_SIZE;
    data[ARRAY_OFFSET + (y as usize) * (MAX_BOARD_WIDTH as usize) + (x as usize)] = value;
}

fn get_pcb_array_element(data: &[u8], x: u8, y: u8) -> u8{
    const ARRAY_OFFSET: usize = OWNER_SIZE + HEALTH_SIZE + SPEED_SIZE + LOCATION_SIZE;
    data[ARRAY_OFFSET + (y as usize) * (MAX_BOARD_WIDTH as usize) + (x as usize)]
}

pub fn create_spacecraft_account<'a>(
    accounts: &'a [AccountInfo<'a>],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let payer_account = next_account_info(accounts_iter)?;
    let new_account = next_account_info(accounts_iter)?;

    let account_size = spacecraft_account_size();
    if new_account.data_len() != account_size{
        return Err(ProgramError::AccountDataTooSmall);
    }
    if new_account.owner.to_string() != crate::ID{
        return Err(ProgramError::IllegalOwner);
    }

    let mut new_data = new_account.try_borrow_mut_data().unwrap();
    new_data[0..32].copy_from_slice(&payer_account.key.to_bytes());

    const MAX_HEALTH: u16 = 3;
    set_health(&mut new_data, MAX_HEALTH);

    set_pcb_array_element(&mut new_data, MAX_BOARD_WIDTH / 2, 0, 1);
    set_pcb_array_element(&mut new_data, MAX_BOARD_WIDTH / 2, 1, 1);
    set_pcb_array_element(&mut new_data, MAX_BOARD_WIDTH / 2, 2, 1);

    Ok(())
}

pub fn upgrade_health<'a>(
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let sender_account = next_account_info(accounts_iter)?;
    let mapping_account = next_account_info(accounts_iter)?;

    Ok(())
}

pub fn add_component<'a>(
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let _sender_account = next_account_info(accounts_iter)?;
    let play_account = next_account_info(accounts_iter)?;

    // TODO(Virax): burn a token here.
    
    let mut data = play_account.try_borrow_mut_data().unwrap();
    set_pcb_array_element(&mut data, instruction_data[1], instruction_data[2], instruction_data[3]);

    Ok(())
}

pub fn remove_component<'a>(
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let _sender_account = next_account_info(accounts_iter)?;
    let play_account = next_account_info(accounts_iter)?;

    // TODO(Virax): return a token here.
    
    let mut data = play_account.try_borrow_mut_data().unwrap();

    let existing_component = get_pcb_array_element(&mut data, instruction_data[1], instruction_data[2]);
    if existing_component > 1{
        set_pcb_array_element(&mut data, instruction_data[1], instruction_data[2], 1);
    }
    else if existing_component == 1{
        set_pcb_array_element(&mut data, instruction_data[1], instruction_data[2], 0);
    }
    else{
        return Err(ProgramError::InvalidInstructionData);
    }

    Ok(())
}

pub fn activate_component<'a>(accounts: &'a [AccountInfo<'a>], instruction_data: &[u8]) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let _sender_account = next_account_info(accounts_iter)?;
    let play_account = next_account_info(accounts_iter)?;
    
    let mut data = play_account.try_borrow_mut_data().unwrap();

    let existing_component = get_pcb_array_element(&mut data, instruction_data[1], instruction_data[2]);
    match existing_component{
        //2 => 
        //3 => add_velocity(),
        _ => Err(ProgramError::InvalidInstructionData),
    }?;

    Ok(())
}
