use methods::spacecraft::{activate_component, claim_reward_and_respawn};
use crate::methods::spacecraft::claim_score;
use solana_program::{
    account_info::AccountInfo,
    entrypoint,
    entrypoint::ProgramResult,
    pubkey::Pubkey,
    program_error::ProgramError,
    msg,
};

pub mod methods;

use crate::methods::initialize_user::initialize_user;
use crate::methods::spacecraft::{
    create_spacecraft_account,
    add_component,
    sync_spaceship_account
};

pub const ID: &str = "5WhmqFKvvxmHcFcsL6aqkpxvkhcqHZvexGxK3fcNpJBn";

// Declare and export the program's entrypoint
entrypoint!(process_instruction);

pub fn process_instruction<'a>(
    program_id: &Pubkey,
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {

    match instruction_data[0] {
        0 => create_spacecraft_account(accounts),
        1 => add_component(program_id, accounts, instruction_data),

        3 => activate_component(accounts, instruction_data),
        10 => claim_reward_and_respawn(program_id, accounts),
        11 => claim_score(program_id, accounts),
        100 => sync_spaceship_account(accounts),
        _ => Err(ProgramError::InvalidInstructionData),
    }
}