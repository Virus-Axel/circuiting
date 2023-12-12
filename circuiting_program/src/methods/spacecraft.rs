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
    let sender_account = next_account_info(accounts_iter)?;
    let mapping_account = next_account_info(accounts_iter)?;

    Ok(())
}

pub fn remove_component<'a>(
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let sender_account = next_account_info(accounts_iter)?;
    let mapping_account = next_account_info(accounts_iter)?;

    Ok(())
}

pub fn travel<'a>(accounts: &'a [AccountInfo<'a>], instruction_data: &[u8]) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let sender_account = next_account_info(accounts_iter)?;
    let mapping_account = next_account_info(accounts_iter)?;

    Ok(())
}
